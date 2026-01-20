`timescale 1ns/1ps
// `define DEBUG

module test_systolic_tb;

    import test_utils_pkg::*;
    
    // Clock and reset
    logic clk = 1;
    logic rst;

    localparam int SYSTOLIC_ARRAY_WIDTH = 2;

    // Column size inputs
    logic [$clog2(SYSTOLIC_ARRAY_WIDTH):0] ub_rd_col_size_in = 0;
    logic ub_rd_col_size_valid_in = 0;

    // DUT left side inputs
    reg [(16 * SYSTOLIC_ARRAY_WIDTH)-1:0] sys_data_in = 0;
    reg sys_start;

    // DUT top side inputs
    reg [(16 * SYSTOLIC_ARRAY_WIDTH)-1:0] sys_weight_in = 0;
    reg [SYSTOLIC_ARRAY_WIDTH-1:0] sys_accept_w = 0;
    reg sys_switch_in;

    // DUT bottom side outputs
    wire [(16 * SYSTOLIC_ARRAY_WIDTH)-1:0] sys_data_out;
    wire [SYSTOLIC_ARRAY_WIDTH-1:0] sys_valid_out;

    wire [15:0] sys_weight_in_arr [SYSTOLIC_ARRAY_WIDTH-1:0];
    wire [15:0] sys_data_in_arr [SYSTOLIC_ARRAY_WIDTH-1:0];
    wire [15:0] sys_data_out_arr [SYSTOLIC_ARRAY_WIDTH-1:0];

    generate
        for (genvar i = 0; i < SYSTOLIC_ARRAY_WIDTH; i++) begin
            assign sys_weight_in_arr[i] = sys_weight_in[(16*(i+1))-1 -:16];
            assign sys_data_in_arr[i] = sys_data_in[(16*(i+1))-1 -:16];
            assign sys_data_out_arr[i] = sys_data_out[(16*(i+1))-1 -:16];
        end
    endgenerate

    int M = 4, N = 2, K = 2;
    // int M = 2, N = 2, K = 2;

    // Matrices for testing
    matrix16_t matA = '{'{to_fixed(1.80078125), to_fixed(2.0)},
                        '{to_fixed(5.48046875), to_fixed(6.0)},
                        '{to_fixed(-15.6796875), to_fixed(-18.859375)},
                        '{to_fixed(7.359375), to_fixed(3.26171875)}};

    matrix16_t matW = '{'{to_fixed(1.0), to_fixed(4.34765625)},
                        '{to_fixed(5.75), to_fixed(1.0)}};
                        

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
    systolic #(
        .SYSTOLIC_ARRAY_WIDTH(SYSTOLIC_ARRAY_WIDTH)
    )dut(
        .clk(clk),
        .rst(rst),

        .ub_rd_col_size_in(ub_rd_col_size_in),
        .ub_rd_col_size_valid_in(ub_rd_col_size_valid_in),

        // DUT left side inputs
        .sys_data_in(sys_data_in),
        .sys_start(sys_start),

        // DUT top side inputs
        .sys_weight_in(sys_weight_in),
        .sys_accept_w(sys_accept_w),
        .sys_switch_in(sys_switch_in),

        // DUT bottom side outputs
        .sys_data_out(sys_data_out),
        .sys_valid_out(sys_valid_out)

    );

    // Generate clock (10 ns period)
    always #5 clk = ~clk;


    // -------------------- Fot Testing --------------------
    int testN = 0;
    bit validating = 0;
    int cycle_count = 0;
    int cycle_zero = 0;


    vector16_t w_col_r[SYSTOLIC_ARRAY_WIDTH];
    vector16_t a_row[SYSTOLIC_ARRAY_WIDTH];
    matrix16_t result;
    matrix16_t systolic_output;

    bit start = 0;
    bit assertionFail = 0;

    initial begin // This generates what in the arch will be the memories
        for (int i = 0; i < SYSTOLIC_ARRAY_WIDTH; i++) begin
            extractColReverse(matW, w_col_r[i], i, N);
            `ifdef DEBUG
                $display("w_col[%.d]_r:", i);
                printVec(w_col_r[i], N);
            `endif
            extractCol(matA, a_row[i], i, M);
            `ifdef DEBUG
                $display("a_row[%.d]:", i);
                printVec(a_row[i], M);
            `endif
        end
    end

    generate
        // Assign column inputs to DUT
        for (genvar col = 0; col < SYSTOLIC_ARRAY_WIDTH; col++) begin
            always @(*) begin
                if (rst) begin
                    // $display("Resetting weight inputs");
                    sys_weight_in[(16*(col+1))-1 -:16] <= 16'b0;
                    sys_accept_w[col] <= 1'b0;
                end else begin
                    if (cycle_count >= col && cycle_count < col + N) begin
                        sys_weight_in[(16*(col+1))-1 -:16] <= w_col_r[col][cycle_count - col];
                        sys_accept_w[col] <= 1'b1;
                    end else begin
                        sys_weight_in[(16*(col+1))-1 -:16] <= 16'b0;
                        sys_accept_w[col] <= 1'b0;
                    end
                end
            end
        end

        // Assign row inputs to DUT
        for (genvar row = 0; row < SYSTOLIC_ARRAY_WIDTH; row++) begin : data_in_assign
            always @(*) begin
                if (rst) begin
                    sys_data_in[(16*(row+1))-1 -:16] <= 16'b0;
                end else begin
                    if (cycle_count >= (SYSTOLIC_ARRAY_WIDTH-1) + row && cycle_count < (SYSTOLIC_ARRAY_WIDTH-1) + row + M) begin
                        sys_data_in[(16*(row+1))-1 -:16] <= a_row[row][cycle_count - (SYSTOLIC_ARRAY_WIDTH -1) - row];
                    end else begin
                        sys_data_in[(16*(row+1))-1 -:16] <= 16'b0;
                    end
                end
            end
        end

        // TODO: Ceck if this always block may work.
        // for (genvar col = 0; col < SYSTOLIC_ARRAY_WIDTH; col++) begin : psum_in_assign
        //     always @(posedge clk or posedge rst) begin
        //         if (rst) begin
        //             for (int row = 0; row < SYSTOLIC_ARRAY_WIDTH; row++) begin
        //                 systolic_output[row][col] = 16'b0;
        //             end
        //         end else if (sys_valid_out[col]) begin
        //             if ( sys_valid_out[col] ) begin
        //                 systolic_output[cycle_count - (SYSTOLIC_ARRAY_WIDTH -1)][col] = sys_data_out[(16*(col+1))-1 -:16];
        //             end
        //         end
        //     end
        // end

        //TODO: Undestend the reason of the +2 offset at L+3
        for (genvar col = 0; col < SYSTOLIC_ARRAY_WIDTH; col++) begin : psum_in_assign
            always @(sys_data_out[(16*(col+1))-1 -:16]) begin
                systolic_output[cycle_count - (SYSTOLIC_ARRAY_WIDTH -1 +2)][col] = sys_data_out[(16*(col+1))-1 -:16];
            end
        end
    endgenerate

    assign sys_switch_in = cycle_count == SYSTOLIC_ARRAY_WIDTH -1;
    assign sys_start = cycle_count >= SYSTOLIC_ARRAY_WIDTH -1 && cycle_count < SYSTOLIC_ARRAY_WIDTH -1 + M; //TODO: check if the upper limit is correct


    // -------------------- Test Procedure --------------------
    bit b;
    initial begin
        vector16_t col_vec;
        cycle_count = -1;
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
endmodule
