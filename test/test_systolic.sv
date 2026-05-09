`timescale 1ns/1ps
// `define DEBUG
// `define DEBUG_MATRIX

module test_systolic_tb;

    import test_utils_pkg::*;
    
    // Clock and reset
    logic clk = 1;
    logic rst;

    localparam int SYSTOLIC_ARRAY_WIDTH = 4;
    int M = 5, N = 4, K = SYSTOLIC_ARRAY_WIDTH;


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

    // Matrices for testing
    matrix16_t matA;

    matrix16_t matW;
                        

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

        for (genvar col = 0; col < SYSTOLIC_ARRAY_WIDTH; col++) begin : psum_in_assign
            always @(posedge clk or posedge rst) begin
                if (rst) begin
                    for (int row = 0; row < SYSTOLIC_ARRAY_WIDTH; row++) begin
                        systolic_output[row][col] = 16'b0;
                    end
                end else if (cycle_count >= 2*N + col && cycle_count < 2*N + col + M) begin
                    systolic_output[cycle_count - (2*N + col)][col] = sys_data_out[(16*(col+1))-1 -:16];
                end
            end
        end
    endgenerate

    assign sys_switch_in = cycle_count == SYSTOLIC_ARRAY_WIDTH -1;
    assign sys_start = cycle_count >= SYSTOLIC_ARRAY_WIDTH -1 && cycle_count < SYSTOLIC_ARRAY_WIDTH -1 + M;


    // -------------------- Test Procedure --------------------
    bit b;
    initial begin
        vector16_t col_vec;
        assert (N <= SYSTOLIC_ARRAY_WIDTH) else begin
            $error("N must be less than or equal to SYSTOLIC_ARRAY_WIDTH");
            $finish;
        end
        assert (K <= SYSTOLIC_ARRAY_WIDTH) else begin
            $error("K must be less than or equal to SYSTOLIC_ARRAY_WIDTH");
            $finish;
        end
        
        populateMatRandom(matA, M, N, -10.0, 10.0);
        // for(int r = 0; r < M; r++) begin
        //     for (int c = 0; c < N; c++) begin
        //         matA[r][c] = to_fixed(-(r * N + c) * 1.0);
        //     end
        // end
        `ifdef DEBUG_MATRIX
            $display("Matrix A:");
            printMat(matA, M, N);
        `endif
        populateMatRandom(matW, N, K, -10.0, 10.0);
        // for(int r = 0; r < N; r++) begin
        //     for (int c = 0; c < K; c++) begin
        //         matW[r][c] = to_fixed(r * N + c + 5.0);
        //     end
        // end
        `ifdef DEBUG_MATRIX
            $display("Matrix W:");
            printMat(matW, N, K);
        `endif
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

        allocMat(systolic_output, M, K);
        // //Disabled test for matMult cause we don't have an identity matrix starting by now
        matMult(matA, matW, result, M, N, K);
        
        extractCol(matA, col_vec, 1, M);
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

        extractColReverse(matA, col_vec, 1, M);
        b = 1;
        foreach (col_vec[i]) begin
            // $display("col_vec[%0d] = %0.1f", i, from_fixed(col_vec[i]));
            if (col_vec[i] !== matA[M - 1 - i][1]) begin
                $display("Test EXTRACT COL REVERSE: FAILED => col_vect[%0d] was %0.1f, expected %0.1f", i, from_fixed(col_vec[i]), from_fixed(matA[M - 1 - i][1]));
                b = 0;
                break;
            end
        end        
        if (b) begin
            $display("Test EXTRACT COL REVERSE: OK");
        end

        /////////////////////// START TEST ///////////////////////
        rst = 1;
        cycle_count = -1;

        @(posedge clk);
        #1;
        rst = 0;
        // Enable all columns
        ub_rd_col_size_in = K;
        ub_rd_col_size_valid_in = 1;
        // Start generating values
        start = 1;
        @(posedge clk);
        #1;

        cycle_count = 0;
        while (cycle_count < M + 2*N + K - 2) begin
            @(posedge clk);
            #1;
            cycle_count <= cycle_count + 1;
        end

        repeat (2) @(posedge clk);

        b = checkMatEqual(systolic_output, result, M, K, 1);
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
