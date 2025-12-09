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

    initial begin
        clk = 1;
        forever #5 clk = ~clk;
    end


    logic valitading = 0;
    int testN = 0;
    initial begin
        $display("Testing converion functions: from_fixed(to_fixed(-3.3984375) = %.8f", from_fixed(to_fixed(-3.3984375)));
        $display("Testing converion functions: from_fixed(to_fixed(4.34765625) = %.8f", from_fixed(to_fixed(4.34765625)));

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
        rst = 0;
        pe_enabled_in = 1;
        pe_accept_w_in = 1;
        pe_weight_in = to_fixed(4.34765625);
        #1;
        valitading = 1'b1;
        if (dut.weight_reg_inactive == to_fixed(0.0)) begin
            $display("Test #%0da OK", testN);
        end else begin
            $display("Test #%0da FAIL => weight_reg_inactive was %f, expected %f", testN, from_fixed(dut.weight_reg_inactive), 0.0);
        end
        if(pe_weight_out == to_fixed(0.0)) begin
            $display("Test #%0db OK", testN);
        end else begin
            $display("Test #%0db FAIL => pe_weight_out was %f, expected %f", testN, from_fixed(pe_weight_out), 0.0);
        end
        #1;
        valitading = 1'b0;

        testN = 1;
        @(posedge clk);
        #1;
        pe_enabled_in = 1;
        pe_accept_w_in = 1;
        pe_weight_in = to_fixed(10.6015625);
        pe_valid_in = 1;
        pe_input_in = to_fixed(2.0);
        pe_switch_in = 1;
        #1;
        valitading = 1'b1;
        if (dut.weight_reg_inactive == to_fixed(4.34765625)) begin
            $display("Test #%0da OK", testN);
        end else begin
            $display("Test #%0da FAIL => weight_reg_inactive was %f, expected %f", testN, from_fixed(dut.weight_reg_inactive), 4.34765625);
        end
        if(dut.weight_reg_active == to_fixed(0.0)) begin
            $display("Test #%0db OK", testN);
        end else begin
            $display("Test #%0db FAIL => weight_reg_active was %f, expected %f", testN, from_fixed(dut.weight_reg_active), 0.0);
        end
        if(pe_weight_out == to_fixed(4.34765625)) begin
            $display("Test #%0dc OK", testN);
        end else begin
            $display("Test #%0dc FAIL => pe_weight_out was %f, expected %f", testN, from_fixed(pe_weight_out), 4.34765625);
        end
        #1;
        valitading = 1'b0;

        testN = 2;
        @(posedge clk);
        #1;
        pe_enabled_in = 1;
        pe_accept_w_in = 1;
        pe_weight_in = to_fixed(5.75);
        pe_valid_in = 1;
        pe_input_in = to_fixed(-3.3984375);
        pe_switch_in = 1;
        #1;
        valitading = 1'b1;
        //Cheking inteternal registers 
        if (dut.weight_reg_inactive == to_fixed(10.6015625)) begin
            $display("Test #%0da OK", testN);
        end else begin
            $display("Test #%0da FAIL => weight_reg_inactive was %f, expected %f", testN, from_fixed(dut.weight_reg_inactive), 10.6015625);
        end
        if(dut.weight_reg_active == to_fixed(4.34765625)) begin
            $display("Test #%0db OK", testN);
        end else begin
            $display("Test #%0db FAIL => weight_reg_active was %f, expected %f", testN, from_fixed(dut.weight_reg_active), 4.34765625);
        end
        //Checking south ouptut
        if(pe_weight_out == to_fixed(10.6015625)) begin
            $display("Test #%0dc OK", testN);
        end else begin
            $display("Test #%0dc FAIL => pe_weight_out was %f, expected %f", testN, from_fixed(pe_weight_out), 10.6015625);
        end
        if(pe_psum_out == to_fixed(0.0)) begin 
            $display("Test #%0dd OK", testN);
        end else begin
            $display("Test #%0dd FAIL => pe_psum_out was %f, expected %f", testN, from_fixed(pe_psum_out), 0.0);
        end
        //Cheching east ouptut
        if(pe_input_out == to_fixed(2.0)) begin
            $display("Test #%0de OK", testN);
        end else begin
            $display("Test #%0de FAIL => pe_input_out was %f, expected %f", testN, from_fixed(pe_input_out), 2.0);
        end
        #1;
        valitading = 1'b0;

        testN = 3;
        @(posedge clk);
        #1;
        pe_enabled_in = 1;
        pe_accept_w_in = 0;
        pe_weight_in = to_fixed(0.0);
        pe_valid_in = 1;
        pe_input_in = to_fixed(19.359375);
        pe_switch_in = 1;
        #1;
        valitading = 1'b1;
        //Cheking inteternal registers
        if(dut.weight_reg_inactive == to_fixed(5.75)) begin
            $display("Test #%0da OK", testN);
        end else begin
            $display("Test #%0da FAIL => weight_reg_inactive was %f, expected %f", testN, from_fixed(dut.weight_reg_inactive), 5.75);
        end 
        if(dut.weight_reg_active == to_fixed(10.6015625)) begin
            $display("Test #%0db OK", testN);
        end else begin
            $display("Test #%0db FAIL => weight_reg_inactive was %f, expected %f", testN, from_fixed(dut.weight_reg_active), 10.6015625);
        end 
        //Checking south ouptut
        if(pe_weight_out == to_fixed(5.75)) begin
            $display("Test #%0dc OK", testN);
        end else begin
            $display("Test #%0dc FAIL => pe_weight_out was %f, expected %f", testN, from_fixed(pe_weight_out), 5.75);
        end
        if(pe_psum_out == to_fixed(8.6953125)) begin 
            $display("Test #%0dd OK", testN);
        end else begin
            $display("Test #%0dd FAIL => pe_psum_out was %f, expected %f", testN, from_fixed(pe_psum_out), 8.6953125);
        end
        //Cheching east ouptut
        if(pe_input_out == to_fixed(-3.3984375)) begin
            $display("Test #%0de OK", testN);
        end else begin
            $display("Test #%0de FAIL => pe_input_out was %f, expected %f", testN, from_fixed(pe_input_out), -3.3984375);
        end
        #1;
        valitading = 1'b0;

        testN = 4;
        @(posedge clk);
        #1; 
        pe_enabled_in = 1;
        pe_accept_w_in = 0;
        pe_weight_in = to_fixed(0.0);
        pe_valid_in = 0;
        pe_input_in = to_fixed(0);
        pe_switch_in = 0;
        #1;
        valitading = 1'b1;
        //Cheking inteternal registers
        if(dut.weight_reg_inactive == to_fixed(5.75)) begin
            $display("Test #%0da OK", testN);
        end else begin
            $display("Test #%0da FAIL => weight_reg_inactive was %f, expected %f", testN, from_fixed(dut.weight_reg_inactive), 5.75);
        end 
        if(dut.weight_reg_active == to_fixed(5.75)) begin
            $display("Test #%0db OK", testN);
        end else begin
            $display("Test #%0db FAIL => weight_reg_inactive was %f, expected %f", testN, from_fixed(dut.weight_reg_inactive), 5.75);
        end 
        //Checking south ouptut
        if(pe_weight_out == to_fixed(0.0)) begin
            $display("Test #%0dc OK", testN);
        end else begin
            $display("Test #%0dc FAIL => pe_weight_out was %f, expected %f", testN, from_fixed(pe_weight_out), 5.75);
        end
        if(pe_psum_out == to_fixed(-36.027344)) begin 
            $display("Test #%0dd OK", testN);
        end else begin
            $display("Test #%0dd FAIL => pe_psum_out was %f, expected %f", testN, from_fixed(pe_psum_out), -36.027344);
        end
        //Cheching east ouptut
        if(pe_input_out == to_fixed(19.359375)) begin
            $display("Test #%0de OK", testN);
        end else begin
            $display("Test #%0de FAIL => pe_input_out was %f, expected %f", testN, from_fixed(pe_input_out), 19.359375);
        end
        #1;
        valitading = 1'b0;
   
        testN = 5;
        @(posedge clk);
        #1; 
        pe_enabled_in = 1;
        pe_accept_w_in = 0;
        pe_weight_in = to_fixed(0.0);
        pe_valid_in = 0;
        pe_input_in = to_fixed(0);
        pe_switch_in = 0;
        #1;
        valitading = 1'b1;
        //Cheking inteternal registers
        if(dut.weight_reg_inactive == to_fixed(5.75)) begin
            $display("Test #%0da OK", testN);
        end else begin
            $display("Test #%0da FAIL => weight_reg_inactive was %f, expected %f", testN, from_fixed(dut.weight_reg_inactive), 5.75);
        end 
        if(dut.weight_reg_active == to_fixed(5.75)) begin
            $display("Test #%0db OK", testN);
        end else begin
            $display("Test #%0db FAIL => weight_reg_inactive was %f, expected %f", testN, from_fixed(dut.weight_reg_inactive), 5.75);
        end 
        //Checking south ouptut
        if(pe_weight_out == to_fixed(0.0)) begin
            $display("Test #%0dc OK", testN);
        end else begin
            $display("Test #%0dc FAIL => pe_weight_out was %f, expected %f", testN, from_fixed(pe_weight_out), 5.75);
        end
        if(pe_psum_out == to_fixed(111.31640625)) begin 
            $display("Test #%0dd OK", testN);
        end else begin
            $display("Test #%0dd FAIL => pe_psum_out was %f, expected %f", testN, from_fixed(pe_psum_out), 111.31640625);
        end
        //Cheching east ouptut
        if(pe_input_out == to_fixed(19.359375)) begin
            $display("Test #%0de OK", testN);
        end else begin
            $display("Test #%0de FAIL => pe_input_out was %f, expected %f", testN, from_fixed(pe_input_out), 19.359375);
        end
        #1;
        valitading = 1'b0;

        repeat(5) @(posedge clk);

        $finish;
    end

endmodule
