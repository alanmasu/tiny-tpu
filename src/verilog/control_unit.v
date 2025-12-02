module control_unit (
	instruction,
	sys_switch_in,
	ub_rd_start_in,
	ub_rd_transpose,
	ub_wr_host_valid_in_1,
	ub_wr_host_valid_in_2,
	ub_rd_col_size,
	ub_rd_row_size,
	ub_rd_addr_in,
	ub_ptr_sel,
	ub_wr_host_data_in_1,
	ub_wr_host_data_in_2,
	vpu_data_pathway,
	inv_batch_size_times_two_in,
	vpu_leak_factor_in
);
	input wire [87:0] instruction;
	output wire sys_switch_in;
	output wire ub_rd_start_in;
	output wire ub_rd_transpose;
	output wire ub_wr_host_valid_in_1;
	output wire ub_wr_host_valid_in_2;
	output wire [1:0] ub_rd_col_size;
	output wire [7:0] ub_rd_row_size;
	output wire [1:0] ub_rd_addr_in;
	output wire [2:0] ub_ptr_sel;
	output wire [15:0] ub_wr_host_data_in_1;
	output wire [15:0] ub_wr_host_data_in_2;
	output wire [3:0] vpu_data_pathway;
	output wire [15:0] inv_batch_size_times_two_in;
	output wire [15:0] vpu_leak_factor_in;
	assign sys_switch_in = instruction[0];
	assign ub_rd_start_in = instruction[1];
	assign ub_rd_transpose = instruction[2];
	assign ub_wr_host_valid_in_1 = instruction[3];
	assign ub_wr_host_valid_in_2 = instruction[4];
	assign ub_rd_col_size = instruction[6:5];
	assign ub_rd_row_size = instruction[14:7];
	assign ub_rd_addr_in = instruction[16:15];
	assign ub_ptr_sel = instruction[19:17];
	assign ub_wr_host_data_in_1 = instruction[35:20];
	assign ub_wr_host_data_in_2 = instruction[51:36];
	assign vpu_data_pathway = instruction[55:52];
	assign inv_batch_size_times_two_in = instruction[71:56];
	assign vpu_leak_factor_in = instruction[87:72];
endmodule
