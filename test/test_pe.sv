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
    
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    initial begin
        rst = 1;
        pe_valid_in = 0;
        pe_accept_w_in = 0;
        pe_input_in = to_fixed(0.0);
        pe_weight_in = to_fixed(0.0);
        pe_psum_in = to_fixed(0.0);
        @(posedge clk);
    
        rst = 0;
        @(posedge clk);
    
        pe_accept_w_in = 1;
        pe_weight_in = to_fixed(69.0);
        @(posedge clk);
    
        pe_accept_w_in = 1;
        pe_weight_in = to_fixed(10.0);
        @(posedge clk);
    
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
