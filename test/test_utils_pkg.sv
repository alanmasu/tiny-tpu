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
    function automatic fixed16_t fixedMAC(fixed16_t a, fixed16_t b, fixed16_t acc);
        logic signed [31:0] prod;
        logic signed [31:0] full_res;
        
        // 1. Moltiplicazione e Arrotondamento (+0.5 LSB)
        prod = (a * b) + 32'sd128; 
        
        // 2. Accumulo con precisione estesa per evitare overflow intermedi
        full_res = (signed'(acc) << 8) + (prod >>> 0); // Lavoriamo in formato Q16.16 temporaneo
        full_res = full_res >>> 8; // Riportiamo a Q24.8

        // 3. Logica di Saturazione (Clipping)
        if (full_res > 32'sd32767)       return 16'h7FFF; // Saturate a +127.996
        else if (full_res < -32'sd32768) return 16'h8000; // Saturate a -128.0
        else                             return fixed16_t'(full_res);
    endfunction

    function automatic void matMult(ref matrix16_t A, ref matrix16_t B, ref matrix16_t C, input int M, input int N, input int K);
        if (C == null) begin
            allocMat(C, M, K);
        end
        for (int i = 0; i < M; i++) begin
            for (int j = 0; j < K; j++) begin
                bit signed [15:0] acc_result = 16'b0;
                bit signed [15:0] mult_16 = 16'b0;
                C[i][j] = 16'b0;
                for (int k = 0; k < N; k++) begin
                    acc_result = fixedMAC(A[i][k], B[k][j], acc_result);
                end
                C[i][j] = acc_result;
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

    function automatic void populateMatRandom(ref matrix16_t mat, input int rows, input int cols, input real min_val, input real max_val);
        // Check if mat is allocated
        if (mat == null) begin
            allocMat(mat, rows, cols);
        end
        for (int i = 0; i < rows; i++) begin
            for (int j = 0; j < cols; j++) begin
                real rand_real;
                rand_real = $urandom_range(0, 1000) / 1000.0 * (max_val - min_val) + min_val;
                mat[i][j] = to_fixed(rand_real);
            end
        end
    endfunction

    function automatic bit checkMatEqual(ref matrix16_t A, ref matrix16_t B, input int rows, input int cols, input bit assertOnFail=0);
        for (int i = 0; i < rows; i++) begin
            for (int j = 0; j < cols; j++) begin
                if (A[i][j] !== B[i][j]) begin
                    if (assertOnFail) begin
                        $error("Matrix mismatch at element [%0d][%0d]: A=%0.7f, B=%0.7f", i, j, from_fixed(A[i][j]), from_fixed(B[i][j]));
                    end
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