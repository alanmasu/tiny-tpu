module tpu (
	clk,
	rst,
	ub_wr_host_data_in,
	ub_wr_host_valid_in,
	ub_rd_start_in,
	ub_rd_transpose,
	ub_ptr_select,
	ub_rd_addr_in,
	ub_rd_row_size,
	ub_rd_col_size,
	learning_rate_in,
	vpu_data_pathway,
	sys_switch_in,
	vpu_leak_factor_in,
	inv_batch_size_times_two_in
);
	parameter signed [31:0] SYSTOLIC_ARRAY_WIDTH = 2;
	input wire clk;
	input wire rst;
	input wire [(SYSTOLIC_ARRAY_WIDTH * 16) - 1:0] ub_wr_host_data_in;
	input wire [0:SYSTOLIC_ARRAY_WIDTH - 1] ub_wr_host_valid_in;
	input wire ub_rd_start_in;
	input wire ub_rd_transpose;
	input wire [8:0] ub_ptr_select;
	input wire [15:0] ub_rd_addr_in;
	input wire [15:0] ub_rd_row_size;
	input wire [15:0] ub_rd_col_size;
	input wire [15:0] learning_rate_in;
	input wire [3:0] vpu_data_pathway;
	input wire sys_switch_in;
	input wire [15:0] vpu_leak_factor_in;
	input wire [15:0] inv_batch_size_times_two_in;
	wire [(SYSTOLIC_ARRAY_WIDTH * 16) - 1:0] ub_wr_data_in;
	wire [0:SYSTOLIC_ARRAY_WIDTH - 1] ub_wr_valid_in;
	wire [15:0] ub_rd_col_size_out;
	wire ub_rd_col_size_valid_out;
	wire [15:0] ub_rd_input_data_out_0;
	wire [15:0] ub_rd_input_data_out_1;
	wire ub_rd_input_valid_out_0;
	wire ub_rd_input_valid_out_1;
	wire [15:0] ub_rd_weight_data_out_0;
	wire [15:0] ub_rd_weight_data_out_1;
	wire ub_rd_weight_valid_out_0;
	wire ub_rd_weight_valid_out_1;
	wire [15:0] ub_rd_bias_data_out_0;
	wire [15:0] ub_rd_bias_data_out_1;
	wire [15:0] ub_rd_Y_data_out_0;
	wire [15:0] ub_rd_Y_data_out_1;
	wire [15:0] ub_rd_H_data_out_0;
	wire [15:0] ub_rd_H_data_out_1;
	wire [15:0] sys_data_out_21;
	wire [15:0] sys_data_out_22;
	wire sys_valid_out_21;
	wire sys_valid_out_22;
	wire [15:0] vpu_data_out_1;
	wire [15:0] vpu_data_out_2;
	wire vpu_valid_out_1;
	wire vpu_valid_out_2;
	assign ub_wr_data_in[(SYSTOLIC_ARRAY_WIDTH - 1) * 16+:16] = vpu_data_out_1;
	assign ub_wr_data_in[(SYSTOLIC_ARRAY_WIDTH - 2) * 16+:16] = vpu_data_out_2;
	assign ub_wr_valid_in[0] = vpu_valid_out_1;
	assign ub_wr_valid_in[1] = vpu_valid_out_2;
	unified_buffer #(.SYSTOLIC_ARRAY_WIDTH(SYSTOLIC_ARRAY_WIDTH)) ub_inst(
		.clk(clk),
		.rst(rst),
		.ub_wr_data_in(ub_wr_data_in),
		.ub_wr_valid_in(ub_wr_valid_in),
		.ub_wr_host_data_in(ub_wr_host_data_in),
		.ub_wr_host_valid_in(ub_wr_host_valid_in),
		.ub_rd_start_in(ub_rd_start_in),
		.ub_rd_transpose(ub_rd_transpose),
		.ub_ptr_select(ub_ptr_select),
		.ub_rd_addr_in(ub_rd_addr_in),
		.ub_rd_row_size(ub_rd_row_size),
		.ub_rd_col_size(ub_rd_col_size),
		.learning_rate_in(learning_rate_in),
		.ub_rd_input_data_out_0(ub_rd_input_data_out_0),
		.ub_rd_input_data_out_1(ub_rd_input_data_out_1),
		.ub_rd_input_valid_out_0(ub_rd_input_valid_out_0),
		.ub_rd_input_valid_out_1(ub_rd_input_valid_out_1),
		.ub_rd_weight_data_out_0(ub_rd_weight_data_out_0),
		.ub_rd_weight_data_out_1(ub_rd_weight_data_out_1),
		.ub_rd_weight_valid_out_0(ub_rd_weight_valid_out_0),
		.ub_rd_weight_valid_out_1(ub_rd_weight_valid_out_1),
		.ub_rd_bias_data_out_0(ub_rd_bias_data_out_0),
		.ub_rd_bias_data_out_1(ub_rd_bias_data_out_1),
		.ub_rd_Y_data_out_0(ub_rd_Y_data_out_0),
		.ub_rd_Y_data_out_1(ub_rd_Y_data_out_1),
		.ub_rd_H_data_out_0(ub_rd_H_data_out_0),
		.ub_rd_H_data_out_1(ub_rd_H_data_out_1),
		.ub_rd_col_size_out(ub_rd_col_size_out),
		.ub_rd_col_size_valid_out(ub_rd_col_size_valid_out)
	);
	systolic systolic_inst(
		.clk(clk),
		.rst(rst),
		.sys_data_in_11(ub_rd_input_data_out_0),
		.sys_data_in_21(ub_rd_input_data_out_1),
		.sys_start(ub_rd_input_valid_out_0),
		.sys_data_out_21(sys_data_out_21),
		.sys_data_out_22(sys_data_out_22),
		.sys_valid_out_21(sys_valid_out_21),
		.sys_valid_out_22(sys_valid_out_22),
		.sys_weight_in_11(ub_rd_weight_data_out_0),
		.sys_weight_in_12(ub_rd_weight_data_out_1),
		.sys_accept_w_1(ub_rd_weight_valid_out_0),
		.sys_accept_w_2(ub_rd_weight_valid_out_1),
		.sys_switch_in(sys_switch_in),
		.ub_rd_col_size_in(ub_rd_col_size_out),
		.ub_rd_col_size_valid_in(ub_rd_col_size_valid_out)
	);
	vpu vpu_inst(
		.clk(clk),
		.rst(rst),
		.vpu_data_pathway(vpu_data_pathway),
		.vpu_data_in_1(sys_data_out_21),
		.vpu_data_in_2(sys_data_out_22),
		.vpu_valid_in_1(sys_valid_out_21),
		.vpu_valid_in_2(sys_valid_out_22),
		.bias_scalar_in_1(ub_rd_bias_data_out_0),
		.bias_scalar_in_2(ub_rd_bias_data_out_1),
		.lr_leak_factor_in(vpu_leak_factor_in),
		.Y_in_1(ub_rd_Y_data_out_0),
		.Y_in_2(ub_rd_Y_data_out_1),
		.inv_batch_size_times_two_in(inv_batch_size_times_two_in),
		.H_in_1(ub_rd_H_data_out_0),
		.H_in_2(ub_rd_H_data_out_1),
		.vpu_data_out_1(vpu_data_out_1),
		.vpu_data_out_2(vpu_data_out_2),
		.vpu_valid_out_1(vpu_valid_out_1),
		.vpu_valid_out_2(vpu_valid_out_2)
	);
endmodule
