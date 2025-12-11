`timescale 1ns/1ps
// `define DEBUG

module test_systolic_tb;

    import test_utils_pkg::*;
    
    // Clock and reset
    logic clk = 1;
    logic rst;

    // Column size inputs
    logic [15:0] ub_rd_col_size_in = 0;
    logic ub_rd_col_size_valid_in = 0;

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

    matrix16_t matW = '{'{to_fixed(1.0), to_fixed(4.34765625)},
                        '{to_fixed(5.75), to_fixed(1.0)}};
                        
    // fixed16_t matA[][] = '{ '{(1.0), (2.0)}, // ok
    //                         '{(3.0), (4.0)},
    //                         '{(5.0), (6.0)},
    //                         '{(7.0), (8.0)} };

    // logic matrix16_t matW[2][2] = '{  '{(1.0), (0.0)},
    //                             '{(0.0), (1.0)} };

    function automatic fixed16_t fixedMAC(input fixed16_t a, input fixed16_t b, input fixed16_t acc);
        bit signed [31:0] mult_temp;
        bit signed [15:0] mult_result;
        begin
            mult_temp = (a) * (b); // 32-bit result
            // Adjust for fixed-point (frac=8) by shifting right 8 bits
            mult_result = mult_temp >>> 8;
            fixedMAC = mult_result + acc;
        end
    endfunction

    // Instantiate the DUT
    systolic dut (
        .clk(clk),
        .rst(rst),

        .ub_rd_col_size_in(ub_rd_col_size_in),
        .ub_rd_col_size_valid_in(ub_rd_col_size_valid_in),

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

    // function automatic int getIndex(input int offset) 
    // begin
    //     index = cycle_count - offset;
    // end
    // endfunction

    // -------------------- Test Procedure --------------------
    bit b;
    initial begin
        
        matrix16_t result;
        vector16_t col_vec;

        // allocMat(result, 2, 4);

        // //Disabled test for matMult cause we don't have an identity matrix starting by now
        // matMult(matA, matW, result, 2, 2, 2);
        
        // b = checkMatEqual(result, matA, 2, 2);
        // if (b) begin
        //     $display("Test MAT MUL: OK");
        // end else begin
        //     $display("Test MAT MUL: FAILED");
        //     $display("Got:");
        //     printMat(result, 2, 2);
        //     $display("Expected:");
        //     printMat(matA, 2, 2);
        // end

        extractCol(matA, col_vec, 1, 2);
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

        extractColReverse(matA, col_vec, 1, 2);
        b = 1;
        foreach (col_vec[i]) begin
            // $display("col_vec[%0d] = %0.1f", i, from_fixed(col_vec[i]));
            if (col_vec[i] !== matA[2 - 1 - i][1]) begin
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
        rst = 0;
        // Enable all columns
        ub_rd_col_size_in = 2;
        ub_rd_col_size_valid_in = 1;
        @(posedge clk);
        #1;


        testN = 1;
        cycle_count = 0;
        // Load last weight in the first column of W
        sys_accept_w_1 = 1;
        sys_weight_in_11 = w_col1_r[cycle_count];
                
        @(posedge clk);
        #1;
        // Load last weight in the first column of W
        cycle_count = cycle_count + 1;
        sys_weight_in_11 = w_col1_r[cycle_count];
        sys_switch_in = 1;
        // Load last weight in the second column of W
        sys_weight_in_12 = w_col2_r[cycle_count - 1];
        sys_accept_w_2 = 1;
        // Load first activation in the first column of A
        sys_data_in_11 = a_row1[cycle_count - 1];
        // Enable switching after first load
        sys_start = 1;
        #1;
        validating = 1;
        if (dut.pe11.weight_reg_inactive == w_col1_r[cycle_count - 1]) begin
            $display("Test #%0da: OK", testN);
        end else begin
            $display("Test #%0da: FAILED - pe11.weight_reg_inactive was %f, expected %f", testN, from_fixed(dut.pe11.weight_reg_inactive), from_fixed(w_col1_r[cycle_count - 1]));
        end
        if (dut.pe11.weight_reg_active == to_fixed(0.0)) begin
            $display("Test #%0db: OK", testN);
        end else begin
            $display("Test #%0db: FAILED - pe11.weight_reg_active was %f, expected %f", testN, from_fixed(dut.pe11.weight_reg_active), 0.0);
        end
        #1;
        validating = 0;

        testN = 2;
        @(posedge clk);
        #1;
        cycle_count = cycle_count + 1;
        // First column weights should be loaded now
        sys_accept_w_1 = 0;
        // Load first weight in the second column of W
        sys_weight_in_12 = w_col2_r[cycle_count - 1];
        // Load second activation in the first column of A
        sys_data_in_11 = a_row1[cycle_count - 1];
        // Load first activation in the second column of A
        sys_data_in_21 = a_row2[cycle_count - 1];
        #1;
        validating = 1;
        // PE 11 checks
        if (dut.pe11.weight_reg_inactive == w_col1_r[cycle_count - 1]) begin
            $display("Test #%0da: OK", testN);
        end else begin
            $display("Test #%0da: FAILED - pe11.weight_reg_inactive was %f, expected %f", testN, from_fixed(dut.pe11.weight_reg_inactive), from_fixed(w_col1_r[cycle_count - 1]));
        end
        if (dut.pe11.weight_reg_active == w_col1_r[cycle_count - 2]) begin
            $display("Test #%0db: OK", testN);
        end else begin
            $display("Test #%0db: FAILED - pe11.weight_reg_active was %f, expected %f", testN, from_fixed(dut.pe11.weight_reg_active), from_fixed(w_col1_r[cycle_count - 2]));
        end
        if (dut.pe11.pe_psum_out == to_fixed(0.0)) begin
            $display("Test #%0dc: OK", testN);
        end else begin
            $display("Test #%0dc: FAILED - pe11.pe_psum_out was %f, expected %f", testN, from_fixed(dut.pe11.pe_psum_out), to_fixed(0.0));
        end
        if (dut.pe11.pe_input_out == a_row1[cycle_count - 2]) begin
            $display("Test #%0dd: OK", testN);
        end else begin
            $display("Test #%0dc: FAILED - pe11.pe_input_out was %f, expected %f", testN, from_fixed(dut.pe11.pe_input_out), to_fixed(1.0));
        end
        #1;
        validating = 0;


        repeat (2) @(posedge clk);

        $display("Test completed.");
        $finish;
    end

endmodule
