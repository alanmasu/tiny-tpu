// test_pe_tb.sv
`timescale 1ns/1ps

module test_pe_tb;
    reg clk;
    reg rst;
    
    reg pe_valid_in;
    reg pe_accept_w_in;
    reg [15:0] pe_input_in;
    reg [15:0] pe_weight_in;
    reg [15:0] pe_psum_in;
    reg pe_switch_in = 0;
    reg pe_enabled_in = 0;
    
    wire pe_valid_out;  // assuming
    wire [15:0] pe_input_out, pe_weight_out, pe_psum_out; // adjust as needed
    
    pe dut (
        .clk(clk),
        .rst(rst),
        .pe_valid_in(pe_valid_in),
        .pe_accept_w_in(pe_accept_w_in),
        .pe_input_in(pe_input_in),
        .pe_weight_in(pe_weight_in),
        .pe_psum_in(pe_psum_in),
        .pe_switch_in(pe_switch_in),
        .pe_enabled(pe_enabled_in),
        .pe_valid_out(pe_valid_out),
        .pe_input_out(pe_input_out),
        .pe_weight_out(pe_weight_out),
        .pe_psum_out(pe_psum_out)
    );
    
    function [15:0] to_fixed(input real val);
        real scaled;
        begin
            scaled = val * (1<<8);
            to_fixed = $rtoi(scaled) & 16'hFFFF;
        end
    endfunction

    function automatic real from_fixed(
        input bit [15:0] val,          // Valore in punto fisso a 16 bit (non signed)
        input int frac_bits = 8        // Numero di bit frazionari (default 8)
    );
        // Variabile intermedia per contenere il valore in complemento a due come intero con segno.
        // Utilizziamo 'int signed' (32 bit) o 'longint signed' (64 bit) per evitare overflow
        // durante il calcolo del complemento a due $val - 2^{16}$.
        int signed signed_val;
        real result;
        
        // --- Passaggio 1: Conversione da 16-bit non signed a Signed (Complemento a Due) ---
        // Logica: Se il bit 15 è impostato, il valore è negativo (val - 2^16).

        if (val[15] == 1) begin
            // Il numero è negativo. Si applica la logica del complemento a due.
            // Utilizziamo $signed(val) per trattare 'val' in un contesto con segno
            // e lo sottraiamo per 2^16 (1 << 16).
            signed_val = $signed(val) - (1 << 16); 
        end else begin
            // Il numero è positivo.
            signed_val = val;
        end
        
        // --- Passaggio 2: Calcolo finale in Virgola Mobile ---
        // Formula: (Valore con segno) / (2^frac_bits)
        
        // Moltiplichiamo il numeratore 'signed_val' per 1.0 (un valore 'real')
        // per forzare l'intero calcolo a eseguire la divisione in aritmetica 'real'.
        result = (signed_val * 1.0) / (1 << frac_bits);

        return result;
    endfunction
    
    initial begin
        clk = 1;
        forever #5 clk = ~clk;
    end
    

    logic valitading = 0;
    int testN = 0;
    initial begin
        rst = 1;
        pe_psum_in = to_fixed(0.0);
        pe_weight_in = to_fixed(0.0);
        pe_accept_w_in = 0;
        pe_input_in = to_fixed(0.0);
        pe_valid_in = 0;
        pe_switch_in = 0;
        pe_enabled_in = 0;
        @(posedge clk);
        #1;

        testN = 1;
        rst = 0;
        pe_enabled_in = 1;    
        pe_accept_w_in = 1;
        pe_weight_in = to_fixed(69.0);
        @(posedge clk);
        #1;
        pe_accept_w_in = 1;
        pe_weight_in = to_fixed(10.0);
        valitading = 1'b1;
        if (dut.weight_reg_inactive == to_fixed(69.0)) begin
            $display("Test #%0da OK", testN);
        end else begin
            $display("Test #%0da FAIL => weight_reg_inactive was %f, expected %f", testN, from_fixed(dut.weight_reg_inactive), 69.0);
        end
        if(dut.weight_reg_active == to_fixed(0.0)) begin
            $display("Test #%0db OK", testN);
        end else begin
            $display("Test #%0db FAIL => weight_reg_active was %f, expected %f", testN, from_fixed(dut.weight_reg_active), 0.0);
        end
        #1;
        valitading = 1'b0;

        @(posedge clk);
        #1;
        pe_accept_w_in = 0;
        pe_switch_in = 1;
        pe_valid_in = 1;
        pe_input_in = to_fixed(2.0);
        pe_psum_in = to_fixed(50.0);
        @(posedge clk);
    
        pe_valid_in = 1;
        @(posedge clk);
    
        pe_valid_in = 0;
        @(posedge clk);
    
        pe_switch_in = 0;
        pe_valid_in = 0;
    
        repeat(3) @(posedge clk);
    
        $finish;
    end

endmodule
