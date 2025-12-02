`timescale 1ns/1ps

module test_systolic_tb;

    // Clock and reset
    logic clk = 0;
    logic rst;

    // DUT signals
    logic sys_accept_w_1;
    logic sys_accept_w_2;
    logic sys_switch_in;

    logic [15:0] sys_weight_in_11;
    logic [15:0] sys_weight_in_12;

    logic [15:0] sys_data_in_11;
    logic [15:0] sys_data_in_21;

    wire [15:0] sys_data_out_21;
    wire [15:0] sys_data_out_22;


    // Instantiate the DUT
    systolic dut (
        .clk(clk),
        .rst(rst),

        .sys_accept_w_1(sys_accept_w_1),
        .sys_accept_w_2(sys_accept_w_2),
        .sys_switch_in(sys_switch_in),

        .sys_weight_in_11(sys_weight_in_11),
        .sys_weight_in_12(sys_weight_in_12),

        .sys_data_in_11(sys_data_in_11),
        .sys_data_in_21(sys_data_in_21),

        .sys_data_out_21(sys_data_out_21),
        .sys_data_out_22(sys_data_out_22)

    );

    // Generate clock (10 ns period)
    always #5 clk = ~clk;

    // --------------- Fixed-point helper (16-bit, frac=8) ----------------
    function automatic logic [15:0] to_fixed (real val);
        real scaled;
        begin
            scaled = val * 256.0; // 1 << 8
            to_fixed = $rtoi(scaled) & 16'hFFFF;
        end
    endfunction

    // -------------------- Test Procedure --------------------
    initial begin
        // Initialize
        rst = 1;
        sys_accept_w_1 = 0;
        sys_accept_w_2 = 0;
        sys_switch_in  = 0;

        sys_weight_in_11 = 0;
        sys_weight_in_12 = 0;

        sys_data_in_11 = 0;
        sys_data_in_21 = 0;


        @(posedge clk);

        // Release reset
        rst = 0;

        // ---------------- Step by step replication of cocotb ----------------

        // Load weight W1 (transposed)
        sys_weight_in_11 = to_fixed(-0.5792);
        sys_accept_w_1   = 1;
        @(posedge clk);

        sys_weight_in_11 = to_fixed(0.2985);
        sys_accept_w_1   = 1;

        sys_weight_in_12 = to_fixed(0.4234);
        sys_accept_w_2   = 1;
        @(posedge clk);

        sys_accept_w_1   = 0;
        sys_weight_in_12 = to_fixed(0.0913);
        sys_accept_w_2   = 1;

        sys_switch_in    = 1;
        sys_data_in_11   = to_fixed(2.0);
        @(posedge clk);

        sys_accept_w_1   = 0;
        sys_accept_w_2   = 0;
        sys_switch_in    = 0;
        sys_data_in_11   = to_fixed(0.0);

        sys_data_in_21   = to_fixed(2.0);
        @(posedge clk);

        sys_data_in_11 = to_fixed(1.0);

        sys_data_in_21 = to_fixed(1.0);
        @(posedge clk);

        sys_data_in_11 = to_fixed(1.0);

        sys_data_in_21 = to_fixed(0.0);
        @(posedge clk);

        sys_data_in_21 = to_fixed(1.0);
        @(posedge clk);

        @(posedge clk);

        repeat (2) @(posedge clk);

        $display("Test completed.");
        $finish;
    end

endmodule
