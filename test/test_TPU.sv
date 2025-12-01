// sv_testbench_tpu.sv
//
// Procedural SystemVerilog testbench — conversione dal cocotb test_tpu.py
// Assunzioni sulle larghezze dei segnali: se diverse, cambiare qui sotto.
//

`timescale 1ns/1ps

module test_TPU;

  // Clock & reset
  logic clk;
  logic rst;

  // UB write interface (2 lanes assumed)
  logic [15:0] ub_wr_host_data_in [1:0];
  logic        ub_wr_host_valid_in [1:0];

  // UB read control
  logic        ub_rd_start_in;
  logic        ub_rd_transpose;
  logic [2:0]  ub_ptr_select;       // small width, increase if needed
  logic [7:0]  ub_rd_addr_in;
  logic [7:0]  ub_rd_row_size;
  logic [7:0]  ub_rd_col_size;

  // VPU / control signals
  logic [15:0] learning_rate_in;
  logic [3:0]  vpu_data_pathway;
  logic [15:0] vpu_leak_factor_in;
  logic [15:0] inv_batch_size_times_two_in;
  logic        sys_switch_in;

  // DUT outputs (assumed)
  logic vpu_valid_out_1;

  // ----------------------------------------------------------------------
  // Instantiate DUT (assumed module name: tpu). Replace module name/ports
  // if your RTL top has a different name or port widths.
  // ----------------------------------------------------------------------
  // Example instance - adjust port names / widths to match your DUT.
  tpu dut (
    .clk(clk),
    .rst(rst),

    .ub_wr_host_data_in(ub_wr_host_data_in),
    .ub_wr_host_valid_in(ub_wr_host_valid_in),

    .ub_rd_start_in(ub_rd_start_in),
    .ub_rd_transpose(ub_rd_transpose),
    .ub_ptr_select(ub_ptr_select),
    .ub_rd_addr_in(ub_rd_addr_in),
    .ub_rd_row_size(ub_rd_row_size),
    .ub_rd_col_size(ub_rd_col_size),

    .learning_rate_in(learning_rate_in),
    .vpu_data_pathway(vpu_data_pathway),
    .vpu_leak_factor_in(vpu_leak_factor_in),
    .inv_batch_size_times_two_in(inv_batch_size_times_two_in),
    .sys_switch_in(sys_switch_in),

    .vpu_valid_out_1(vpu_valid_out_1)
    // add any other ports if your DUT exposes them
  );

  // ----------------------------------------------------------------------
  // Clock generation (10 ns period -> #5 half period)
  // ----------------------------------------------------------------------
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // ----------------------------------------------------------------------
  // Helper: to_fixed conversion (real -> 16-bit signed fixed with 8 frac bits)
  // returns unsigned 16-bit pattern (same as Python & 0xFFFF)
  // ----------------------------------------------------------------------
  function automatic logic [15:0] to_fixed(input real val, input int frac_bits = 8);
    integer scaled;
    real   scale_r;
    begin
      scale_r = val * (1 << frac_bits);
      // round toward nearest (handle sign)
      if (scale_r >= 0.0) scaled = $rtoi(scale_r + 0.5);
      else                scaled = $rtoi(scale_r - 0.5);
      to_fixed = logic'(scaled & 16'hFFFF);
    end
  endfunction

  // small convenience task to wait N clock cycles
  task automatic wait_cycles(input int n);
    integer i;
    begin
      for (i = 0; i < n; i = i + 1)
        @(posedge clk);
    end
  endtask

  // ----------------------------------------------------------------------
  // Main test sequence (translated from cocotb test_tpu.py)
  // ----------------------------------------------------------------------
  initial begin : test_main
    // initialize signals
    rst = 1;

    ub_wr_host_data_in[0] = 16'h0000;
    ub_wr_host_data_in[1] = 16'h0000;
    ub_wr_host_valid_in[0] = 1'b0;
    ub_wr_host_valid_in[1] = 1'b0;

    ub_rd_start_in = 1'b0;
    ub_rd_transpose = 1'b0;
    ub_ptr_select = 3'd0;
    ub_rd_addr_in = 8'd0;
    ub_rd_row_size = 8'd0;
    ub_rd_col_size = 8'd0;

    learning_rate_in = 16'h0000;
    vpu_data_pathway = 4'h0;
    sys_switch_in = 1'b0;
    vpu_leak_factor_in = 16'h0000;
    inv_batch_size_times_two_in = 16'h0000;

    // wait a rising edge
    @(posedge clk);

    // release reset and set some inputs
    rst = 0;
    learning_rate_in = to_fixed(0.75);
    vpu_leak_factor_in = to_fixed(0.5);
    inv_batch_size_times_two_in = to_fixed(2.0/4.0); // batch size = len(X) = 4 in cocotb
    @(posedge clk);

    // ------------------------
    // Load X, Y, W1, B1, W2, B2 into UB (in that order)
    // The cocotb sequence wrote many values across two lanes.
    // We'll mirror that exactly as procedural assigns + posedge waits.
    // ------------------------

    // Following the cocotb pattern: write X[0][0], then for loop writes...
    ub_wr_host_data_in[0] = to_fixed(0.0); // X[0][0]
    ub_wr_host_valid_in[0] = 1;
    @(posedge clk);

    // write next X items (mimic cocotb sequence)
    // X = [[0.,0.],[0.,1.],[1.,0.],[1.,1.]]
    ub_wr_host_data_in[0] = to_fixed(0.0);  ub_wr_host_valid_in[0] = 1; // X[1][0]
    ub_wr_host_data_in[1] = to_fixed(0.0);  ub_wr_host_valid_in[1] = 1; // X[0][1]
    @(posedge clk);

    ub_wr_host_data_in[0] = to_fixed(1.0);  ub_wr_host_valid_in[0] = 1; // X[2][0]
    ub_wr_host_data_in[1] = to_fixed(1.0);  ub_wr_host_valid_in[1] = 1; // X[1][1]
    @(posedge clk);

    ub_wr_host_data_in[0] = to_fixed(1.0);  ub_wr_host_valid_in[0] = 1; // X[3][0]
    ub_wr_host_data_in[1] = to_fixed(0.0);  ub_wr_host_valid_in[1] = 1; // X[2][1]
    @(posedge clk);

    // Now start writing Y and remaining data following cocotb ordering
    // Y = [0,1,1,0]
    ub_wr_host_data_in[0] = to_fixed(0.0);  ub_wr_host_valid_in[0] = 1; // Y[0]
    ub_wr_host_data_in[1] = to_fixed(1.0);  ub_wr_host_valid_in[1] = 1; // X[3][1]
    @(posedge clk);

    ub_wr_host_data_in[0] = to_fixed(1.0);  ub_wr_host_valid_in[0] = 1; // Y[1]
    ub_wr_host_data_in[1] = 16'h0000;       ub_wr_host_valid_in[1] = 0;
    @(posedge clk);

    ub_wr_host_data_in[0] = to_fixed(1.0);  ub_wr_host_valid_in[0] = 1; // Y[2]
    ub_wr_host_data_in[1] = 16'h0000;       ub_wr_host_valid_in[1] = 0;
    @(posedge clk);

    ub_wr_host_data_in[0] = to_fixed(0.0);  ub_wr_host_valid_in[0] = 1; // Y[3]
    ub_wr_host_data_in[1] = 16'h0000;       ub_wr_host_valid_in[1] = 0;
    @(posedge clk);

    // W1 and B1 and W2, B2 as in the cocotb file:
    // W1 = [[0.2985, -0.5792],[0.0913, 0.4234]]
    ub_wr_host_data_in[0] = to_fixed(0.2985); ub_wr_host_valid_in[0] = 1;
    ub_wr_host_data_in[1] = 16'h0000;         ub_wr_host_valid_in[1] = 0;
    @(posedge clk);

    ub_wr_host_data_in[0] = to_fixed(0.0913); ub_wr_host_valid_in[0] = 1;
    ub_wr_host_data_in[1] = to_fixed(-0.5792);ub_wr_host_valid_in[1] = 1;
    @(posedge clk);

    ub_wr_host_data_in[0] = to_fixed(-0.4939); ub_wr_host_valid_in[0] = 1; // B1[0]
    ub_wr_host_data_in[1] = to_fixed(0.4234);   ub_wr_host_valid_in[1] = 1;
    @(posedge clk);

    ub_wr_host_data_in[0] = to_fixed(0.5266);  ub_wr_host_valid_in[0] = 1; // W2[0]
    ub_wr_host_data_in[1] = to_fixed(0.189);   ub_wr_host_valid_in[1] = 1; // B1[1]
    @(posedge clk);

    ub_wr_host_data_in[0] = to_fixed(0.6358);  ub_wr_host_valid_in[0] = 1; // B2
    ub_wr_host_data_in[1] = to_fixed(0.2958);  ub_wr_host_valid_in[1] = 1; // W2[1]
    @(posedge clk);

    // clear write lanes
    ub_wr_host_data_in[0] = 16'h0000; ub_wr_host_valid_in[0] = 0;
    ub_wr_host_data_in[1] = 16'h0000; ub_wr_host_valid_in[1] = 0;
    @(posedge clk);

    // ------------------------------------------------------------------
    // Load W1^T into systolic array (reading from UB to top of systolic)
    // mirror the cocotb sequence of toggling ub_rd_* and waits
    // ------------------------------------------------------------------
    ub_rd_start_in = 1;
    ub_rd_transpose = 1;
    ub_ptr_select = 3'd1;
    ub_rd_addr_in = 8'd12;
    ub_rd_row_size = 8'd2;
    ub_rd_col_size = 8'd2;
    @(posedge clk);

    ub_rd_start_in = 0;
    ub_rd_transpose = 0;
    ub_ptr_select = 3'd0;
    ub_rd_addr_in = 8'd0;
    ub_rd_row_size = 0;
    ub_rd_col_size = 0;
    @(posedge clk);

    // Load X into systolic array (UB -> left side)
    ub_rd_start_in = 1;
    ub_rd_transpose = 0;
    ub_ptr_select = 3'd0;
    ub_rd_addr_in = 8'd0;
    ub_rd_row_size = 8'd4;
    ub_rd_col_size = 8'd2;
    vpu_data_pathway = 4'b1100; // forward pass
    @(posedge clk);

    ub_rd_start_in = 0;
    ub_rd_transpose = 0;
    ub_ptr_select = 3'd0;
    ub_rd_addr_in = 8'd0;
    ub_rd_row_size = 8'd0;
    ub_rd_col_size = 8'd0;
    sys_switch_in = 1;
    @(posedge clk);

    // Read B1 from UB for 4 clock cycles (ptr_select = 2)
    ub_rd_start_in = 1;
    ub_rd_transpose = 0;
    ub_ptr_select = 3'd2;
    ub_rd_addr_in = 8'd16;
    ub_rd_row_size = 8'd4;
    ub_rd_col_size = 8'd2;
    sys_switch_in = 0;
    @(posedge clk);

    ub_rd_start_in = 0;
    ub_rd_transpose = 0;
    ub_ptr_select = 3'd0;
    ub_rd_addr_in = 8'd0;
    ub_rd_row_size = 8'd0;
    ub_rd_col_size = 8'd0;

    // wait until last value of vpu is done (FallingEdge equivalent)
    @(negedge vpu_valid_out_1);

    // Load W2^T
    ub_rd_start_in = 1;
    ub_rd_transpose = 1;
    ub_ptr_select = 3'd1;
    ub_rd_addr_in = 8'd18;
    ub_rd_row_size = 8'd1;
    ub_rd_col_size = 8'd2;
    @(posedge clk);

    ub_rd_start_in = 0;
    ub_rd_transpose = 0;
    ub_ptr_select = 3'd0;
    ub_rd_addr_in = 8'd0;
    ub_rd_row_size = 8'd0;
    ub_rd_col_size = 8'd0;
    @(posedge clk);

    // Load H1
    ub_rd_start_in = 1;
    ub_rd_transpose = 0;
    ub_ptr_select = 3'd0;
    ub_rd_addr_in = 8'd21;
    ub_rd_row_size = 8'd4;
    ub_rd_col_size = 8'd2;
    vpu_data_pathway = 4'b1111; // transition pathway
    @(posedge clk);

    ub_rd_start_in = 0;
    ub_rd_transpose = 0;
    ub_ptr_select = 3'd0;
    ub_rd_addr_in = 8'd0;
    ub_rd_row_size = 8'd0;
    ub_rd_col_size = 8'd0;
    sys_switch_in = 1;
    @(posedge clk);

    // Read B2 from UB for 4 cycles (ptr_select = 2)
    ub_rd_start_in = 1;
    ub_rd_transpose = 0;
    ub_ptr_select = 3'd2;
    ub_rd_addr_in = 8'd20;
    ub_rd_row_size = 8'd4;
    ub_rd_col_size = 8'd1;
    sys_switch_in = 0;
    @(posedge clk);

    ub_rd_start_in = 0;
    ub_rd_transpose = 0;
    ub_ptr_select = 3'd0;
    ub_rd_addr_in = 8'd0;
    ub_rd_row_size = 8'd0;
    ub_rd_col_size = 8'd0;
    @(posedge clk);

    // Reading Y values for loss modules
    ub_rd_start_in = 1;
    ub_rd_transpose = 0;
    ub_ptr_select = 3'd3;
    ub_rd_addr_in = 8'd8;
    ub_rd_row_size = 8'd4;
    ub_rd_col_size = 8'd1;
    sys_switch_in = 0;
    @(posedge clk);

    ub_rd_start_in = 0;
    ub_rd_transpose = 0;
    ub_ptr_select = 3'd0;
    ub_rd_addr_in = 8'd0;
    ub_rd_row_size = 8'd0;
    ub_rd_col_size = 8'd0;
    @(posedge clk);

    // Read biases (B2) to gradient descent modules in VPU
    ub_rd_start_in = 1;
    ub_rd_transpose = 0;
    ub_ptr_select = 3'd5;
    ub_rd_addr_in = 8'd20;
    ub_rd_row_size = 8'd4;
    ub_rd_col_size = 8'd1;
    @(posedge clk);

    ub_rd_start_in = 0;
    ub_rd_transpose = 0;
    ub_ptr_select = 3'd0;
    ub_rd_addr_in = 8'd0;
    ub_rd_row_size = 8'd0;
    ub_rd_col_size = 8'd0;
    @(posedge clk);

    @(negedge vpu_valid_out_1);

    // Load W2 into top of systolic array
    ub_rd_start_in = 1;
    ub_rd_transpose = 0;
    ub_ptr_select = 3'd1;
    ub_rd_addr_in = 8'd18;
    ub_rd_row_size = 8'd1;
    ub_rd_col_size = 8'd2;
    @(posedge clk);

    ub_rd_start_in = 0;
    ub_rd_transpose = 0;
    ub_ptr_select = 3'd0;
    ub_rd_addr_in = 8'd0;
    ub_rd_row_size = 8'd0;
    ub_rd_col_size = 8'd0;
    @(posedge clk);

    // Load dL/dZ into left side of systolic array
    ub_rd_start_in = 1;
    ub_rd_transpose = 0;
    ub_ptr_select = 3'd0;
    ub_rd_addr_in = 8'd29;
    ub_rd_row_size = 8'd4;
    ub_rd_col_size = 8'd1;
    vpu_data_pathway = 4'b0001;
    @(posedge clk);

    ub_rd_start_in = 0;
    ub_rd_transpose = 0;
    ub_ptr_select = 3'd0;
    ub_rd_addr_in = 8'd0;
    ub_rd_row_size = 8'd0;
    ub_rd_col_size = 8'd0;
    sys_switch_in = 1;
    @(posedge clk);

    // Read H1 from UB to VPU
    ub_rd_start_in = 1;
    ub_rd_transpose = 0;
    ub_ptr_select = 3'd4;
    ub_rd_addr_in = 8'd21;
    ub_rd_row_size = 8'd4;
    ub_rd_col_size = 8'd2;
    sys_switch_in = 0;
    @(posedge clk);

    // Read biases (B1) to gradient descent modules in VPU
    ub_rd_start_in = 1;
    ub_rd_transpose = 0;
    ub_ptr_select = 3'd5;
    ub_rd_addr_in = 8'd16;
    ub_rd_row_size = 8'd4;
    ub_rd_col_size = 8'd2;
    @(posedge clk);

    ub_rd_start_in = 0;
    ub_rd_transpose = 0;
    ub_ptr_select = 3'd0;
    ub_rd_addr_in = 8'd0;
    ub_rd_row_size = 8'd0;
    ub_rd_col_size = 8'd0;

    @(negedge vpu_valid_out_1);

    // ------------------------------------------------------------------
    // Now leaf nodes / gradient calculations: replicate the rest of the
    // UB read/write patterns present in the cocotb test.
    // (Due to length, I map the major control patterns exactly as above.)
    // ------------------------------------------------------------------

    // Calculating W1 gradients (first tile)
    ub_rd_start_in = 1; ub_rd_transpose = 0; ub_ptr_select = 3'd1;
    ub_rd_addr_in = 8'd0; ub_rd_row_size = 8'd2; ub_rd_col_size = 8'd2;
    @(posedge clk);

    ub_rd_start_in = 0; ub_rd_transpose = 0; ub_ptr_select = 3'd0;
    ub_rd_addr_in = 8'd0; ub_rd_row_size = 8'd0; ub_rd_col_size = 8'd0;
    @(posedge clk);

    // load (dL/dZ1)^T tile
    ub_rd_start_in = 1; ub_rd_transpose = 1; ub_ptr_select = 3'd0;
    ub_rd_addr_in = 8'd33; ub_rd_row_size = 8'd2; ub_rd_col_size = 8'd2;
    vpu_data_pathway = 4'b0000;
    @(posedge clk);

    ub_rd_start_in = 0; ub_rd_transpose = 0; ub_ptr_select = 3'd0;
    ub_rd_addr_in = 8'd0; ub_rd_row_size = 8'd0; ub_rd_col_size = 8'd0;
    sys_switch_in = 1;
    @(posedge clk);

    // Read weights (W1) to VPU
    ub_rd_start_in = 1; ub_rd_transpose = 0; ub_ptr_select = 3'd6;
    ub_rd_addr_in = 8'd12; ub_rd_row_size = 8'd2; ub_rd_col_size = 8'd2;
    sys_switch_in = 0;
    @(posedge clk);

    ub_rd_start_in = 0; ub_rd_transpose = 0; ub_ptr_select = 3'd0;
    ub_rd_addr_in = 8'd0; ub_rd_row_size = 8'd0; ub_rd_col_size = 8'd0;
    @(negedge vpu_valid_out_1);

    // Load second H1 tile (for next gradient tile)
    ub_rd_start_in = 1; ub_rd_transpose = 0; ub_ptr_select = 3'd1;
    ub_rd_addr_in = 8'd4; ub_rd_row_size = 8'd2; ub_rd_col_size = 8'd2;
    @(posedge clk);
    ub_rd_start_in = 0; ub_rd_transpose = 0; ub_ptr_select = 3'd0;
    ub_rd_addr_in = 8'd0; ub_rd_row_size = 8'd0; ub_rd_col_size = 8'd0;
    @(posedge clk);

    // Load second (dL/dZ1)^T tile
    ub_rd_start_in = 1; ub_rd_transpose = 1; ub_ptr_select = 3'd0;
    ub_rd_addr_in = 8'd37; ub_rd_row_size = 8'd2; ub_rd_col_size = 8'd2;
    vpu_data_pathway = 4'b0000;
    @(posedge clk);

    ub_rd_start_in = 0; ub_rd_transpose = 0; ub_ptr_select = 3'd0;
    ub_rd_addr_in = 8'd0; ub_rd_row_size = 8'd0; ub_rd_col_size = 8'd0;
    sys_switch_in = 1;
    @(posedge clk);

    // Read weights (W1) to VPU again
    ub_rd_start_in = 1; ub_rd_transpose = 0; ub_ptr_select = 3'd6;
    ub_rd_addr_in = 8'd12; ub_rd_row_size = 8'd2; ub_rd_col_size = 8'd2;
    sys_switch_in = 0;
    @(posedge clk);

    ub_rd_start_in = 0; ub_rd_transpose = 0; ub_ptr_select = 3'd0;
    ub_rd_addr_in = 8'd0; ub_rd_row_size = 8'd0; ub_rd_col_size = 8'd0;
    @(negedge vpu_valid_out_1);

    // Now W2 gradients flow (first H1 tile)
    ub_rd_start_in = 1; ub_rd_transpose = 0; ub_ptr_select = 3'd1;
    ub_rd_addr_in = 8'd21; ub_rd_row_size = 8'd2; ub_rd_col_size = 8'd2;
    @(posedge clk);

    ub_rd_start_in = 0; ub_rd_transpose = 0; ub_ptr_select = 3'd0;
    ub_rd_addr_in = 8'd0; ub_rd_row_size = 8'd0; ub_rd_col_size = 8'd0;
    @(posedge clk);

    // Load first (dL/dZ2)^T tile
    ub_rd_start_in = 1; ub_rd_transpose = 1; ub_ptr_select = 3'd0;
    ub_rd_addr_in = 8'd29; ub_rd_row_size = 8'd2; ub_rd_col_size = 8'd1;
    vpu_data_pathway = 4'b0000;
    @(posedge clk);

    ub_rd_start_in = 0; ub_rd_transpose = 0; ub_ptr_select = 3'd0;
    ub_rd_addr_in = 8'd0; ub_rd_row_size = 8'd0; ub_rd_col_size = 8'd0;
    sys_switch_in = 1;
    @(posedge clk);

    // Read W2 to VPU
    ub_rd_start_in = 1; ub_rd_transpose = 0; ub_ptr_select = 3'd6;
    ub_rd_addr_in = 8'd18; ub_rd_row_size = 8'd1; ub_rd_col_size = 8'd2;
    sys_switch_in = 0;
    @(posedge clk);

    ub_rd_start_in = 0; ub_rd_transpose = 0; ub_ptr_select = 3'd0;
    ub_rd_addr_in = 8'd0; ub_rd_row_size = 8'd0; ub_rd_col_size = 8'd0;
    @(negedge vpu_valid_out_1);

    // Load second H1 tile
    ub_rd_start_in = 1; ub_rd_transpose = 0; ub_ptr_select = 3'd1;
    ub_rd_addr_in = 8'd25; ub_rd_row_size = 8'd2; ub_rd_col_size = 8'd2;
    @(posedge clk);
    ub_rd_start_in = 0; ub_rd_transpose = 0; ub_ptr_select = 3'd0;
    ub_rd_addr_in = 8'd0; ub_rd_row_size = 8'd0; ub_rd_col_size = 8'd0;
    @(posedge clk);

    // Load second (dL/dZ2)^T tile
    ub_rd_start_in = 1; ub_rd_transpose = 1; ub_ptr_select = 3'd0;
    ub_rd_addr_in = 8'd31; ub_rd_row_size = 8'd2; ub_rd_col_size = 8'd1;
    vpu_data_pathway = 4'b0000;
    @(posedge clk);

    ub_rd_start_in = 0; ub_rd_transpose = 0; ub_ptr_select = 3'd0;
    ub_rd_addr_in = 8'd0; ub_rd_row_size = 8'd0; ub_rd_col_size = 8'd0;
    sys_switch_in = 1;
    @(posedge clk);

    // Read W2 to VPU again
    ub_rd_start_in = 1; ub_rd_transpose = 0; ub_ptr_select = 3'd6;
    ub_rd_addr_in = 8'd18; ub_rd_row_size = 8'd1; ub_rd_col_size = 8'd2;
    sys_switch_in = 0;
    @(posedge clk);

    ub_rd_start_in = 0; ub_rd_transpose = 0; ub_ptr_select = 3'd0;
    ub_rd_addr_in = 8'd0; ub_rd_row_size = 8'd0; ub_rd_col_size = 8'd0;
    @(negedge vpu_valid_out_1);

    // Wait some cycles and finish
    wait_cycles(10);
    $display("Test complete - finishing simulation.");
    #10;
    $finish;
  end // test_main

endmodule
