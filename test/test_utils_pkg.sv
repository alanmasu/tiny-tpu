package test_utils_pkg;

    typedef bit signed[15:0] fixed16_t;
    typedef fixed16_t matrix16_t [][];
    typedef fixed16_t vector16_t [];


     // --------------- Fixed-point (16-bit, frac=8) to logic ----------------
    function automatic logic [15:0] to_fixed (input real val);
        real scaled;
        begin
            scaled = val * 256.0; // 1 << 8
            to_fixed = $rtoi(scaled) & 16'hFFFF;
        end
    endfunction

    // --------------- Logic to Fixed-point (16-bit, frac=8) ----------------
    function automatic real from_fixed(input bit [15:0] val);
        real result;

        bit signed [15:0] signed_val;
        if (val[15] == 1) begin
            signed_val = $signed(val) - (1 << 16); 
        end else begin
            signed_val = val;
        end
        result = (signed_val * 1.0) / (1 << 8);
        return result;
    endfunction

    // --------------- Print Matrix ----------------
    function automatic void printMat(ref matrix16_t input_matrix, input int rows, input int cols);
        for (int i = 0; i < rows; i++) begin
            for (int j = 0; j < cols; j++) begin
                $write("%0.8f ", from_fixed(input_matrix[i][j]));
            end
            $write("\n");
        end
    endfunction

    // Print Vector
    function automatic void printVec(ref vector16_t input_vector, input int length);
        foreach (input_vector[i]) begin
            $write("%0.2f ", from_fixed(input_vector[i]));
        end
        $write("\n");
    endfunction

    // --------------- Matrix Mult ----------------
    function automatic void matMult(ref matrix16_t A, ref matrix16_t B, ref matrix16_t C, input int M, input int N, input int K);
        if (C == null) begin
            allocMat(C, M, K);
        end
        for (int i = 0; i < M; i++) begin
            for (int j = 0; j < K; j++) begin
                bit signed [15:0] acc_result = 16'b0;
                bit signed [15:0] mult_16 = 16'b0;
                C[i][j] = 16'b0;
                // $display("Calculating C[%0d][%0d]\n\t", i, j);
                for (int k = 0; k < N; k++) begin
                    // Fixed-point multiplication and accumulation
                    bit signed [31:0] mult_result;
                    bit signed [31:0] mult_result_rounded;
                    mult_result = $signed(A[i][k]) * $signed(B[k][j]);
                    mult_result_rounded = mult_result + 32'h00000080;
                    // mult_result = (A[i][k]) * (B[k][j]);
                    // Adjust for fixed-point (frac=8)
                    // mult_16 = mult_result >>> 8;
                    
                    mult_16 = mult_result_rounded[23:8];
                    acc_result = acc_result + mult_16;
                    // $write("(%0.1f, %0.1f)", from_fixed(mult_result[15:0]), from_fixed(acc_result));

                end
                C[i][j] = acc_result;
                // $display("\nC[%0d][%0d] (acc) = %0.2f", i, j, from_fixed(acc_result));
                // $display("C[%0d][%0d]       = %0.2f", i, j, from_fixed(C[i][j]));
            end
        end
    endfunction

    function automatic void allocMat(ref matrix16_t mat, input int rows, input int cols);
        mat = new[rows];
        for (int i = 0; i < rows; i++) begin
            mat[i] = new[cols];
        end
    endfunction

    function automatic void freeMat(ref matrix16_t mat, input int rows);
        for (int i = 0; i < rows; i++) begin
            mat[i].delete();
        end
        mat.delete();
    endfunction

    function automatic bit checkMatEqual(ref matrix16_t A, ref matrix16_t B, input int rows, input int cols);
        for (int i = 0; i < rows; i++) begin
            for (int j = 0; j < cols; j++) begin
                if (A[i][j] !== B[i][j]) begin
                    return 0;
                end
            end
        end
        return 1;
    endfunction

    function automatic void extractCol(ref matrix16_t mat, ref vector16_t col_vec, input int col_idx, input int rows);
        if(col_vec == null) begin
            col_vec = new[rows];
        end
        for (int i = 0; i < rows; i++) begin
            col_vec[i] = mat[i][col_idx];
        end
    endfunction
    
    function automatic void extractColReverse(ref matrix16_t mat, ref vector16_t col_vec, input int col_idx, input int rows);
        if(col_vec == null) begin
            col_vec = new[rows];
        end
        for (int i = 0; i < rows; i++) begin
            col_vec[i] = mat[rows -1 - i][col_idx];
        end
    endfunction

    function automatic void extractRow(ref matrix16_t mat, ref vector16_t row_vec, input int row_idx, input int cols);
        if(row_vec == null) begin
            row_vec = new[cols];
        end
        row_vec = mat[row_idx];
    endfunction

endpackage