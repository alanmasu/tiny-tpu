`timescale 1ns/1ps

// 2x2 systolic array
module systolic #(
    parameter int SYSTOLIC_ARRAY_WIDTH = 2
)(
    input logic clk,
    input logic rst,

    // input signals from left side of systolic array
    input logic [15:0] sys_data_in_1x,
    input logic [15:0] sys_data_in_2x,
    input logic sys_start,    // start signal

    // input signals from top of systolic array
    input logic [15:0] sys_weight_in_x1, 
    input logic [15:0] sys_weight_in_x2,
    input logic sys_accept_w_1,             // accept weight signal propagates only from top to bottom in column 1
    input logic sys_accept_w_2,             // accept weight signal propagates only from top to bottom in column 2

    input logic sys_switch_in,               // switch signal copies weight from shadow buffer to active buffer. propagates from top left to bottom right

    input logic [15:0] ub_rd_col_size_in,
    input logic ub_rd_col_size_valid_in,

    // output signals from bottom side of systolic array
    output logic [15:0] sys_data_out_x1,
    output logic [15:0] sys_data_out_x2,
    output wire sys_valid_out_x1, 
    output wire sys_valid_out_x2
);
    //West to East
    // input_out for each PE (left to right)
    logic [15:0] pe_input_out_11;   // pe11 out to pe12 in
    logic [15:0] pe_input_out_21;   // pe21 out to pe22 in
    wire pe_valid_out_11;   // pe11 out to pe12 in
    wire pe_valid_out_21;   // pe21 out to pe22 in

    // psum_out for each PE (top to bottom)
    logic [15:0] pe_psum_out_11;    // pe11 out to pe21 in
    logic [15:0] pe_psum_out_12;    // pe12 out to pe22 in
    logic [15:0] pe_weight_out_11;  // pe11 out to pe21 in
    logic [15:0] pe_weight_out_12;  // pe12 out to pe22 in
    logic pe_accept_w_out_11;      // pe11 out to pe21 in
    logic pe_accept_w_out_12;      // pe12 out to pe22 in

    

    // switch_out for each PE
    logic pe_switch_out_11;  // pe11 out to pe12 in
    logic pe_switch_out_11;  // pe21 out to pe22 in
    

    // PE columns to enable
    logic [1:0] pe_enabled;

    // top left PE
    pe pe11 (
        .clk(clk),
        .rst(rst),

        // North wires of PE
        .pe_psum_in(16'b0),
        .pe_weight_in(sys_weight_in_x1),
        .pe_accept_w_in(sys_accept_w_1),

        // West wires of PE
        .pe_input_in(sys_data_in_1x),
        .pe_valid_in(sys_start),
        .pe_switch_in(sys_switch_in),
        .pe_enabled(pe_enabled[0]),

        // South wires of the PE
        .pe_psum_out(pe_psum_out_11),
        .pe_weight_out(pe_weight_out_11),
        .pe_accept_w_out(pe_accept_w_out_11),


        // East wires of the PE
        .pe_input_out(pe_input_out_11),
        .pe_valid_out(pe_valid_out_11), 
        .pe_switch_out(pe_switch_out_11)
    );

    // top right PE
    pe pe12 (
        .clk(clk),
        .rst(rst),

        // North wires of PE
        .pe_psum_in(16'b0),
        .pe_weight_in(sys_weight_in_x2),
        .pe_accept_w_in(sys_accept_w_2),

        // West wires of PE
        .pe_input_in(sys_data_in_2x),
        .pe_valid_in(pe_valid_out_11),
        .pe_switch_in(sys_switch_in),
        .pe_enabled(pe_enabled[1]),

        // South wires of the PE
        .pe_psum_out(pe_psum_out_12),
        .pe_weight_out(pe_weight_out_12),
        .pe_accept_w_out(pe_accept_w_out_12),

        // East wires of the PE
        .pe_switch_out(pe_switch_out_12),
        .pe_input_out(pe_input_out_11),
        .pe_valid_out(pe_valid_out_x1) 
    );

    // bottom left PE
    pe pe21 (
        .clk(clk),
        .rst(rst),

        // North wires of PE
        .pe_psum_in(pe_psum_out_11),
        .pe_weight_in(pe_weight_out_11),
        .pe_accept_w_in(pe_accept_w_out_11),

        // West wires of PE
        .pe_input_in(sys_data_in_2x),
        .pe_valid_in(sys_start),
        .pe_switch_in(sys_switch_11),
        .pe_enabled(pe_enabled[0]),

        // South wires of the PE
        .pe_psum_out(sys_psum_out_x1),
        .pe_weight_out(),


        // East wires of the PE
        .pe_input_out(pe_input_out_21),
        .pe_valid_out(pe_valid_out_21), 
        .pe_switch_out()
    );

    // bottom right PE
    pe pe22 (
        .clk(clk),
        .rst(rst),

        // North wires of PE
        .pe_psum_in(pe_psum_out_12),
        .pe_weight_in(pe_weight_out_12),
        .pe_accept_w_in(pe_accept_w_out_12),

        // West wires of PE
        .pe_input_in(sys_data_in_2x),
        .pe_valid_in(sys_start),
        .pe_switch_in(sys_switch_in),
        .pe_enabled(pe_enabled[1]),

        // South wires of the PE
        .pe_psum_out(sys_psum_out_x2),
        .pe_weight_out(),

        // East wires of the PE
        .pe_input_out(),
        .pe_valid_out(),
        .pe_switch_out()
    );

    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            pe_enabled <= '0;
        end else begin
            if(ub_rd_col_size_valid_in) begin
                pe_enabled <= (1 << ub_rd_col_size_in) - 1;
            end
        end
    end

endmodule