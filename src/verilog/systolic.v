module systolic (
	clk,
	rst,
	sys_data_in_1x,
	sys_data_in_2x,
	sys_start,
	sys_weight_in_x1,
	sys_weight_in_x2,
	sys_accept_w_1,
	sys_accept_w_2,
	sys_switch_in,
	ub_rd_col_size_in,
	ub_rd_col_size_valid_in,
	sys_data_out_x1,
	sys_data_out_x2,
	sys_valid_out_x1,
	sys_valid_out_x2
);
	parameter signed [31:0] SYSTOLIC_ARRAY_WIDTH = 2;
	input wire clk;
	input wire rst;
	input wire [15:0] sys_data_in_1x;
	input wire [15:0] sys_data_in_2x;
	input wire sys_start;
	input wire [15:0] sys_weight_in_x1;
	input wire [15:0] sys_weight_in_x2;
	input wire sys_accept_w_1;
	input wire sys_accept_w_2;
	input wire sys_switch_in;
	input wire [15:0] ub_rd_col_size_in;
	input wire ub_rd_col_size_valid_in;
	output wire [15:0] sys_data_out_x1;
	output wire [15:0] sys_data_out_x2;
	output wire sys_valid_out_x1;
	output wire sys_valid_out_x2;
	wire [15:0] pe_input_out_11;
	wire [15:0] pe_input_out_21;
	wire pe_valid_out_11;
	wire pe_valid_out_21;
	wire [15:0] pe_psum_out_11;
	wire [15:0] pe_psum_out_12;
	wire [15:0] pe_weight_out_11;
	wire [15:0] pe_weight_out_12;
	wire pe_accept_w_out_11;
	wire pe_accept_w_out_12;
	wire pe_switch_out_11;
	wire pe_switch_out_12;
	reg [1:0] pe_enabled;
	pe pe11(
		.clk(clk),
		.rst(rst),
		.pe_psum_in(16'b0000000000000000),
		.pe_weight_in(sys_weight_in_x1),
		.pe_accept_w_in(sys_accept_w_1),
		.pe_input_in(sys_data_in_1x),
		.pe_valid_in(sys_start),
		.pe_switch_in(sys_switch_in),
		.pe_enabled(pe_enabled[0]),
		.pe_psum_out(pe_psum_out_11),
		.pe_weight_out(pe_weight_out_11),
		.pe_accept_w_out(pe_accept_w_out_11),
		.pe_input_out(pe_input_out_11),
		.pe_valid_out(pe_valid_out_11),
		.pe_switch_out(pe_switch_out_11)
	);
	wire pe_valid_out_x1;
	pe pe12(
		.clk(clk),
		.rst(rst),
		.pe_psum_in(16'b0000000000000000),
		.pe_weight_in(sys_weight_in_x2),
		.pe_accept_w_in(sys_accept_w_2),
		.pe_input_in(sys_data_in_2x),
		.pe_valid_in(pe_valid_out_11),
		.pe_switch_in(sys_switch_in),
		.pe_enabled(pe_enabled[1]),
		.pe_psum_out(pe_psum_out_12),
		.pe_weight_out(pe_weight_out_12),
		.pe_accept_w_out(pe_accept_w_out_12),
		.pe_switch_out(pe_switch_out_12),
		.pe_input_out(pe_input_out_11),
		.pe_valid_out(pe_valid_out_x1)
	);
	pe pe21(
		.clk(clk),
		.rst(rst),
		.pe_psum_in(pe_psum_out_11),
		.pe_weight_in(pe_weight_out_11),
		.pe_accept_w_in(pe_accept_w_out_11),
		.pe_input_in(sys_data_in_2x),
		.pe_valid_in(pe_valid_out_11),
		.pe_switch_in(pe_switch_out_11),
		.pe_enabled(pe_enabled[0]),
		.pe_psum_out(sys_data_out_x1),
		.pe_weight_out(),
		.pe_input_out(pe_input_out_21),
		.pe_valid_out(pe_valid_out_21),
		.pe_switch_out(pe_valid_out_21)
	);
	pe pe22(
		.clk(clk),
		.rst(rst),
		.pe_psum_in(pe_psum_out_12),
		.pe_weight_in(pe_weight_out_12),
		.pe_accept_w_in(pe_accept_w_out_12),
		.pe_input_in(sys_data_in_2x),
		.pe_valid_in(pe_valid_out_21),
		.pe_switch_in(pe_switch_out_12),
		.pe_enabled(pe_enabled[1]),
		.pe_psum_out(sys_data_out_x2),
		.pe_weight_out(),
		.pe_input_out(),
		.pe_valid_out(),
		.pe_switch_out()
	);
	always @(posedge clk or posedge rst)
		if (rst)
			pe_enabled <= 1'sb0;
		else if (ub_rd_col_size_valid_in)
			pe_enabled <= (1 << ub_rd_col_size_in) - 1;
endmodule
