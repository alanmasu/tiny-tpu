`timescale 1ns/1ps
`define DEBUG

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
                        '{to_fixed(5.0), to_fixed(6.0)}};

    matrix16_t matW = '{'{to_fixed(1.0), to_fixed(0.0)},
                        '{to_fixed(0.0), to_fixed(1.0)}};
                        
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
        .sys_data_in_1x(sys_data_in_11),
        .sys_data_in_2x(sys_data_in_21),
        .sys_start(sys_start),

        // DUT top side inputs
        .sys_weight_in_x1(sys_weight_in_11),
        .sys_weight_in_x2(sys_weight_in_12),
        .sys_accept_w_1(sys_accept_w_1),
        .sys_accept_w_2(sys_accept_w_2),
        .sys_switch_in(sys_switch_in),

        // DUT bottom side outputs
        .sys_data_out_x1(sys_data_out_21),
        .sys_data_out_x2(sys_data_out_22),
        .sys_valid_out_x1(sys_valid_out_21),
        .sys_valid_out_x2(sys_valid_out_22)

    );

    // Generate clock (10 ns period)
    always #5 clk = ~clk;


    // -------------------- Fot Testing --------------------
    int testN = 0;
    bit validating = 0;
    int cycle_count = 0;

    fixed16_t w1, w2, a1, a2;

    vector16_t w_col1_r, w_col2_r;
    vector16_t a_row1, a_row2;

    bit update_cycle = 1;
    bit automatic_values_sel = 1;
    initial begin
        extractColReverse(matW, w_col1_r, 0, 2);
        `ifdef DEBUG
            $display("w_col1_r:");
            printVec(w_col1_r, 4);
        `endif
        extractColReverse(matW, w_col2_r, 1, 2);
        `ifdef DEBUG
            $display("w_col2_r:");
            printVec(w_col2_r, 4);
        `endif
        extractCol(matA, a_row1, 0, 2);
        `ifdef DEBUG
            $display("a_row1:");
            printVec(a_row1, 2);
        `endif
        extractCol(matA, a_row2, 1, 2);
        `ifdef DEBUG
            $display("a_row2:");
            printVec(a_row2, 2);
        `endif
    end

    // always @(posedge clk) begin
    //     if (automatic_values_sel) begin
    //         sys_weight_in_11 = w_col1_r[(cycle_count) % 2];
    //         sys_weight_in_12 = w_col2_r[(cycle_count + 1) % 2];
    //         sys_data_in_11 = a_row1[(cycle_count + 1) % 2];
    //         sys_data_in_21 = a_row2[(cycle_count + 2) % 2];
    //     end else begin
    //         sys_weight_in_11 = 'z;
    //         sys_weight_in_12 = 'z;
    //         sys_data_in_11 = 'z;
    //         sys_data_in_21 = 'z;
    //     end

    //     if (update_cycle)
    //         cycle_count = cycle_count + 1;

    // end    

    function automatic int getIndex(input int offset) 
        index = cycle_count - offset;
    endfunction

    // -------------------- Test Procedure --------------------
    bit b;
    initial begin
        
        matrix16_t result;
        vector16_t col_vec;

        // allocMat(result, 2, 4);

        matMult(matA, matW, result, 2, 4, 2);
        
        b = checkMatEqual(result, matA, 4, 2);
        if (b) begin
            $display("Test MAT MUL: OK");
        end else begin
            $display("Test MAT MUL: FAILED");
            $display("Got:");
            printMat(result, 4, 2);
            $display("Expected:");
            printMat(matA, 4, 2);
        end

        extractCol(result, col_vec, 1, 4);
        b = 1;
        foreach (col_vec[i]) begin
            // $display("col_vec[%0d] = %0.1f", i, from_fixed(col_vec[i]));
            if (col_vec[i] !== matA[i][1]) begin
                $display("Test EXTRACT COL: FAILED => col_vect[%0d] was %0.1f, expected %0.1f", i, from_fixed(col_vec[i]), from_fixed(matA[i][1]));
                b = 0;
                break;
            end
        end        
        if (b) begin
            $display("Test EXTRACT COL: OK");
        end

        extractColReverse(result, col_vec, 1, 4);
        b = 1;
        foreach (col_vec[i]) begin
            // $display("col_vec[%0d] = %0.1f", i, from_fixed(col_vec[i]));
            if (col_vec[i] !== matA[4 -1 - i][1]) begin
                $display("Test EXTRACT COL REVERSE: FAILED => col_vect[%0d] was %0.1f, expected %0.1f", i, from_fixed(col_vec[i]), from_fixed(matA[4 - 1 - i][1]));
                b = 0;
                break;
            end
        end        
        if (b) begin
            $display("Test EXTRACT COL REVERSE: OK");
        end

        // Initialize
        rst = 1;

        @(posedge clk);
        #1;
        testN = 0
        cycle_count = 0;
        rst = 0;
        sys_accept_w_1 = 1;
        sys_weight_in_11 = w_col1_r[cycle_count];
                
        @(posedge clk);
        #1;
        cycle_count = cycle_count + 1;
        sys_weight_in_11 = w_col1_r[cycle_count];

        sys_weight_in_12 = w_col2_r[cycle_count - 1];
        sys_accept_w_2 = 1;

        sys_data_in_11 = a_row1[cycle_count - 1];
        sys_start = 1;





        #1
        testN = 1;
        validating = 1;


        @(posedge clk);

        sys_accept_w_1   = 0;
        sys_accept_w_2   = 1;

        sys_switch_in    = 1;
        @(posedge clk);

        sys_accept_w_1   = 0;
        sys_accept_w_2   = 0;
        sys_switch_in    = 0;

        @(posedge clk);


        @(posedge clk);

        @(posedge clk);


        @(posedge clk);

        repeat (2) @(posedge clk);

        $display("Test completed.");
        $finish;
    end

endmodule
