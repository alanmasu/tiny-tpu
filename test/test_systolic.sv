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
    wire [15:0] sys_data_out_x1;
    wire [15:0] sys_data_out_x2;
    wire sys_valid_out_21;
    wire sys_valid_out_22;

    int M = 4, N = 2, K = 2;
    // int M = 2, N = 2, K = 2;

    // Matrices for testing
    matrix16_t matA = '{'{to_fixed(1.80078125), to_fixed(2.0)},
                        '{to_fixed(5.48046875), to_fixed(6.0)},
                        '{to_fixed(-15.6796875), to_fixed(-18.859375)},
                        '{to_fixed(7.359375), to_fixed(3.26171875)}};
    // matrix16_t matA = '{'{to_fixed(1.0), to_fixed(2.0)},
    //                     '{to_fixed(5.0), to_fixed(6.0)}};

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
        .sys_data_out_x1(sys_data_out_x1),
        .sys_data_out_x2(sys_data_out_x2),
        .sys_valid_out_x1(sys_valid_out_1),
        .sys_valid_out_x2(sys_valid_out_2)

    );

    // Generate clock (10 ns period)
    always #5 clk = ~clk;


    // -------------------- Fot Testing --------------------
    int testN = 0;
    bit validating = 0;
    int cycle_count = 0;
    int cycle_zero = 0;

    fixed16_t w1, w2, a1, a2;

    vector16_t w_col1_r, w_col2_r;
    vector16_t a_row1, a_row2;
    matrix16_t result;
    matrix16_t systolic_output;

    bit start = 0;
    bit assertionFail = 0;

    initial begin
        extractColReverse(matW, w_col1_r, 0, N);
        `ifdef DEBUG
            $display("w_col1_r:");
            printVec(w_col1_r, N);
        `endif
        extractColReverse(matW, w_col2_r, 1, N);
        `ifdef DEBUG
            $display("w_col2_r:");
            printVec(w_col2_r, N);
        `endif
        extractCol(matA, a_row1, 0, M);
        `ifdef DEBUG
            $display("a_row1:");
            printVec(a_row1, M);
        `endif
        extractCol(matA, a_row2, 1, M);
        `ifdef DEBUG
            $display("a_row2:");
            printVec(a_row2, M);
        `endif
    end

    // W11
    always @(posedge clk) begin
        if (start) begin
            #2;
            if(cycle_count < N) begin
                sys_weight_in_11 <= w_col1_r[(cycle_count) % N];
                sys_accept_w_1 <= 1;
            end else begin
                sys_accept_w_1 <= 0;
            end
            if(cycle_count - 1 >= 0 && cycle_count - 1 < N) begin
                sys_weight_in_12 <= w_col2_r[(cycle_count - 1) % N];
                sys_accept_w_2 <= 1;
                sys_switch_in <= 1;
            end else begin
                sys_accept_w_2 <= 0;
                sys_switch_in <= 0;
            end 
            if(cycle_count - 1 >= 0 && cycle_count - 1 < M) begin
                sys_data_in_11 <= a_row1[(cycle_count - 1) % M];
                sys_start <= 1;
            end else begin
                sys_start <= 0;
            end 
            if(cycle_count - 2 >= 0 && cycle_count - 2 < M) begin
                sys_data_in_21 <= a_row2[(cycle_count - 2) % M];
            end
        // end else begin
        //     sys_weight_in_11 <= 'z;
        //     sys_weight_in_12 <= 'z;
        //     sys_data_in_11 <= 'z;
        //     sys_data_in_21 <= 'z;
        end
    end

    // function automatic int getIndex(input int offset) 
    // begin
    //     index = cycle_count - offset;
    // end
    // endfunction

    // -------------------- Test Procedure --------------------
    bit b;
    initial begin
        vector16_t col_vec;
        allocMat(systolic_output, M, K);
        // //Disabled test for matMult cause we don't have an identity matrix starting by now
        matMult(matA, matW, result, 4, 2, 2);
        
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
        // Start generating values
        start = 1;
        @(posedge clk);
        #1;

        cycle_count = 0;
        repeat (1 + 2*M + 1) begin
            @(posedge clk);
            #1;
            cycle_count <= cycle_count + 1;
        end
        // // Load last weight in the first column of W
        // sys_accept_w_1 = 1;
        // sys_weight_in_11 = w_col1_r[cycle_count];
                
        // @(posedge clk);
        // #1;
        // // Load last weight in the first column of W
        // cycle_count = cycle_count + 1;
        // sys_weight_in_11 = w_col1_r[cycle_count];
        // sys_switch_in = 1;
        // // Load last weight in the second column of W
        // sys_weight_in_12 = w_col2_r[cycle_count - 1];
        // sys_accept_w_2 = 1;
        // // Load first activation in the first column of A
        // sys_data_in_11 = a_row1[cycle_count - 1];
        // // Enable switching after first load
        // sys_start = 1;

        // @(posedge clk);
        // #1;
        // cycle_count = cycle_count + 1;
        // // First column weights should be loaded now
        // sys_accept_w_1 = 0;
        // // Load first weight in the second column of W
        // sys_weight_in_12 = w_col2_r[cycle_count - 1];
        // // Load second activation in the first column of A
        // sys_data_in_11 = a_row1[cycle_count - 1];
        // // Load first activation in the second column of A
        // sys_data_in_21 = a_row2[cycle_count - 2];
        // #1;

        // @(posedge clk);
        // #1;
        // cycle_count = cycle_count + 1;
        // sys_start = 0;
        // sys_accept_w_2 = 0;
        // sys_switch_in = 0;
        // sys_data_in_21 = a_row2[cycle_count - 2];
        
        // @(posedge clk);
        // #1; 
        // cycle_count = cycle_count + 1;

        // @(posedge clk);
        // #1; 
        // cycle_count = cycle_count + 1;

        // @(posedge clk);
        // #1; 
        // cycle_count = cycle_count + 1;

        repeat (2) @(posedge clk);

        b = checkMatEqual(systolic_output, result, M, K);
        assert (b == 1)
            else begin
                $error("Assertion FAILED: systolic_output differ from expected result");
                $display("systolic_output was:");
                printMat(systolic_output, M, K);
                $display("expected:");
                printMat(result, M, K);
                $finish;
            end
        $display("Test completed.");
        $finish;
    end

    int row1 = 0;
    always @(sys_data_out_x1) begin
        if(cycle_count >= 1 + N && row1 < M)  begin
            systolic_output[row1][0] = sys_data_out_x1;
            row1++;
        end
    end

    int row2 = 0;
    always @(sys_data_out_x2) begin
        if(cycle_count >= 1 + N && row2 < M)  begin
            systolic_output[row2][1] = sys_data_out_x2;
            row2++;
        end
    end

    // always @(rst, cycle_count) begin
    //     if(rst != 1) begin
    //         if(cycle_count > 2 && cycle_count < 2 + M) begin
    //             assert (dut.pe11.pe_psum_out == fixedMAC(matA[cycle_count - 3][0], matW[0][0], 0))
    //                 else begin
    //                     $error("Assertion FAILED: pe11.pe_psum_out was %f, expected: %f, @cycle_count: %0d", from_fixed(dut.pe11.pe_psum_out), from_fixed(fixedMAC(matA[cycle_count - 3][0], matW[0][0], 0)), cycle_count);
    //                     assertionFail = 1;
    //                     @(posedge clk);
    //                     $finish;
    //                 end
    //         end
    //     end
    // end

    // always @(rst, cycle_count) begin
    //     if(rst != 1) begin
    //         if(cycle_count > 3 && cycle_count < 3 + M) begin
    //             assert (dut.pe12.pe_psum_out == fixedMAC(matA[cycle_count - 4][0], matW[0][1], 0))
    //                 else begin 
    //                     $error("Assertion FAILED: pe12.pe_psum_out was %f, expected: %f, @cycle_count: %0d", from_fixed(dut.pe12.pe_psum_out), from_fixed(fixedMAC(matA[cycle_count - 4][0], matW[0][1], 0)), cycle_count);
    //                     assertionFail = 1;
    //                     @(posedge clk);
    //                     $finish;
    //                 end
    //         end
    //     end
    // end

    // always @(rst, cycle_count) begin
    //     if(rst != 1) begin
    //         if(cycle_count > 4 && cycle_count < 4 + M) begin
    //             assert (dut.pe21.mult.out == fixedMAC(matA[cycle_count - 4][1], matW[1][0], 0))
    //                 else begin 
    //                     $error("Assertion FAILED: pe21.mult.out was %f, expected: %f, @cycle_count: %0d", from_fixed(dut.pe21.mult.out), from_fixed(fixedMAC(matA[cycle_count - 4][1], matW[1][0], 0)), cycle_count);
    //                     assertionFail = 1;
    //                     @(posedge clk);
    //                     $finish;
    //                 end
    //             assert (dut.sys_data_out_x1 == result[cycle_count - 4][0])
    //                 else begin 
    //                     $error("Assertion FAILED: dut.sys_data_out_x1 was %f, expected: %f, @cycle_count: %0d", from_fixed(dut.sys_data_out_x1), from_fixed(result[cycle_count - 4][0]), cycle_count);
    //                     assertionFail = 1;
    //                     @(posedge clk);
    //                     $finish;
    //                 end
    //         end
    //     end
    // end

    // always @(rst, cycle_count) begin
    //     if(rst != 1) begin
    //         if(cycle_count > 5 && cycle_count < 5 + M) begin
    //             assert (dut.pe22.mult.out == fixedMAC(matA[cycle_count - 5][1], matW[1][1], 0))
    //                 else begin
    //                     $error("Assertion FAILED: pe22.mult.out was %f, expected: %f, @cycle_count: %0d", from_fixed(dut.pe12.pe_psum_out), from_fixed(fixedMAC(matA[cycle_count - 5][1], matW[0][1], 0)), cycle_count);
    //                     assertionFail = 1;
    //                     @(posedge clk);
    //                     $finish;
    //                 end
    //             assert (dut.sys_data_out_x2 == result[cycle_count - 5][1])
    //                 else begin 
    //                     $error("Assertion FAILED: dut.sys_data_out_x1 was %f, expected: %f, @cycle_count: %0d", from_fixed(dut.sys_data_out_x2), from_fixed(result[cycle_count - 5][1]), cycle_count);
    //                     assertionFail = 1;
    //                     @(posedge clk);
    //                     $finish;
    //                 end
    //         end
    //     end
    // end

endmodule
