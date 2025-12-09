`timescale 1ns/1ps

module test_systolic_tb;

    import test_utils_pkg::*;
    
    // Clock and reset
    logic clk = 1;
    logic rst;

    // DUT left side inputs
    logic [15:0] sys_data_in_11 = 0;
    logic [15:0] sys_data_in_21 = 0;
    logic sys_start = 0;

    // DUT top side inputs
    logic [15:0] sys_weight_in_11 = 0;
    logic [15:0] sys_weight_in_12 = 0;
    logic sys_accept_w_1 = 0;
    logic sys_accept_w_2 = 0;
    logic sys_switch_in = 0;

    // DUT bottom side outputs
    wire [15:0] sys_data_out_21;
    wire [15:0] sys_data_out_22;
    wire sys_valid_out_21;
    wire sys_valid_out_22;

    // Matrices for testing
    matrix16_t matA = '{'{to_fixed(1.0), to_fixed(2.0)},
                        '{to_fixed(3.0), to_fixed(4.0)},
                        '{to_fixed(5.0), to_fixed(6.0)},
                        '{to_fixed(7.0), to_fixed(8.0)} };

    matrix16_t matW = '{'{to_fixed(1.0), to_fixed(0.0)},
                        '{to_fixed(0.0), to_fixed(1.0)} };
    // fixed16_t matA[][] = '{ '{(1.0), (2.0)}, // ok
    //                         '{(3.0), (4.0)},
    //                         '{(5.0), (6.0)},
    //                         '{(7.0), (8.0)} };

    // logic matrix16_t matW[2][2] = '{  '{(1.0), (0.0)},
    //                             '{(0.0), (1.0)} };



    // Instantiate the DUT
    systolic dut (
        .clk(clk),
        .rst(rst),

        // DUT left side inputs
        .sys_data_in_11(sys_data_in_11),
        .sys_data_in_21(sys_data_in_21),
        .sys_start(sys_start),

        // DUT top side inputs
        .sys_weight_in_11(sys_weight_in_11),
        .sys_weight_in_12(sys_weight_in_12),
        .sys_accept_w_1(sys_accept_w_1),
        .sys_accept_w_2(sys_accept_w_2),
        .sys_switch_in(sys_switch_in),

        // DUT bottom side outputs
        .sys_data_out_21(sys_data_out_21),
        .sys_data_out_22(sys_data_out_22),
        .sys_valid_out_21(sys_valid_out_21),
        .sys_valid_out_22(sys_valid_out_22)

    );

    // Generate clock (10 ns period)
    always #5 clk = ~clk;

    // -------------------- Test Procedure --------------------
    bit b;
    initial begin
        
        matrix16_t result;

        allocMat(result, 4, 2);

        matMult(matA, matW, result, 4, 2, 2);
        
        b = checkMatEqual(result, matA, 4, 2);
        if (b) begin
            $display("Matrix multiplication test passed.");
        end else begin
            $display("Matrix multiplication test failed.");
            $display("Expected:");
            printMat(matA, 4, 2);
            $display("Got:");
            printMat(result, 4, 2);
        end

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
