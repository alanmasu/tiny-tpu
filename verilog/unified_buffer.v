`default_nettype none
module unified_buffer (
	clk,
	rst,
	ub_wr_data_in,
	ub_wr_valid_in,
	ub_wr_host_data_in,
	ub_wr_host_valid_in,
	ub_rd_start_in,
	ub_rd_transpose,
	ub_ptr_select,
	ub_rd_addr_in,
	ub_rd_row_size,
	ub_rd_col_size,
	learning_rate_in,
	ub_rd_input_data_out_0,
	ub_rd_input_data_out_1,
	ub_rd_input_valid_out_0,
	ub_rd_input_valid_out_1,
	ub_rd_weight_data_out_0,
	ub_rd_weight_data_out_1,
	ub_rd_weight_valid_out_0,
	ub_rd_weight_valid_out_1,
	ub_rd_bias_data_out_0,
	ub_rd_bias_data_out_1,
	ub_rd_Y_data_out_0,
	ub_rd_Y_data_out_1,
	ub_rd_H_data_out_0,
	ub_rd_H_data_out_1,
	ub_rd_col_size_out,
	ub_rd_col_size_valid_out
);
	reg _sv2v_0;
	parameter signed [31:0] UNIFIED_BUFFER_WIDTH = 128;
	parameter signed [31:0] SYSTOLIC_ARRAY_WIDTH = 2;
	input wire clk;
	input wire rst;
	input wire [(SYSTOLIC_ARRAY_WIDTH * 16) - 1:0] ub_wr_data_in;
	input wire [0:SYSTOLIC_ARRAY_WIDTH - 1] ub_wr_valid_in;
	input wire [(SYSTOLIC_ARRAY_WIDTH * 16) - 1:0] ub_wr_host_data_in;
	input wire [0:SYSTOLIC_ARRAY_WIDTH - 1] ub_wr_host_valid_in;
	input wire ub_rd_start_in;
	input wire ub_rd_transpose;
	input wire [8:0] ub_ptr_select;
	input wire [15:0] ub_rd_addr_in;
	input wire [15:0] ub_rd_row_size;
	input wire [15:0] ub_rd_col_size;
	input wire [15:0] learning_rate_in;
	output wire [15:0] ub_rd_input_data_out_0;
	output wire [15:0] ub_rd_input_data_out_1;
	output wire ub_rd_input_valid_out_0;
	output wire ub_rd_input_valid_out_1;
	output wire [15:0] ub_rd_weight_data_out_0;
	output wire [15:0] ub_rd_weight_data_out_1;
	output wire ub_rd_weight_valid_out_0;
	output wire ub_rd_weight_valid_out_1;
	output wire [15:0] ub_rd_bias_data_out_0;
	output wire [15:0] ub_rd_bias_data_out_1;
	output wire [15:0] ub_rd_Y_data_out_0;
	output wire [15:0] ub_rd_Y_data_out_1;
	output wire [15:0] ub_rd_H_data_out_0;
	output wire [15:0] ub_rd_H_data_out_1;
	output reg [15:0] ub_rd_col_size_out;
	output reg ub_rd_col_size_valid_out;
	reg [15:0] ub_memory [0:UNIFIED_BUFFER_WIDTH - 1];
	reg [15:0] ub_rd_input_data_out [0:SYSTOLIC_ARRAY_WIDTH - 1];
	reg ub_rd_input_valid_out [0:SYSTOLIC_ARRAY_WIDTH - 1];
	reg [15:0] ub_rd_weight_data_out [0:SYSTOLIC_ARRAY_WIDTH - 1];
	reg ub_rd_weight_valid_out [0:SYSTOLIC_ARRAY_WIDTH - 1];
	reg [15:0] ub_rd_bias_data_out [0:SYSTOLIC_ARRAY_WIDTH - 1];
	reg [15:0] ub_rd_Y_data_out [0:SYSTOLIC_ARRAY_WIDTH - 1];
	reg [15:0] ub_rd_H_data_out [0:SYSTOLIC_ARRAY_WIDTH - 1];
	reg [15:0] wr_ptr;
	reg [15:0] rd_input_ptr;
	reg [15:0] rd_input_row_size;
	reg [15:0] rd_input_col_size;
	reg [15:0] rd_input_time_counter;
	reg rd_input_transpose;
	reg signed [15:0] rd_weight_ptr;
	reg [15:0] rd_weight_row_size;
	reg [15:0] rd_weight_col_size;
	reg [15:0] rd_weight_time_counter;
	reg rd_weight_transpose;
	reg [15:0] rd_weight_skip_size;
	reg [15:0] rd_bias_ptr;
	reg [15:0] rd_bias_row_size;
	reg [15:0] rd_bias_col_size;
	reg [15:0] rd_bias_time_counter;
	reg [15:0] rd_Y_ptr;
	reg [15:0] rd_Y_row_size;
	reg [15:0] rd_Y_col_size;
	reg [15:0] rd_Y_time_counter;
	reg [15:0] rd_H_ptr;
	reg [15:0] rd_H_row_size;
	reg [15:0] rd_H_col_size;
	reg [15:0] rd_H_time_counter;
	reg [15:0] rd_grad_bias_ptr;
	reg [15:0] rd_grad_bias_row_size;
	reg [15:0] rd_grad_bias_col_size;
	reg [15:0] rd_grad_bias_time_counter;
	reg [15:0] rd_grad_weight_ptr;
	reg [15:0] rd_grad_weight_row_size;
	reg [15:0] rd_grad_weight_col_size;
	reg [15:0] rd_grad_weight_time_counter;
	reg [15:0] value_old_in [0:SYSTOLIC_ARRAY_WIDTH - 1];
	reg grad_descent_valid_in [0:SYSTOLIC_ARRAY_WIDTH - 1];
	wire [15:0] value_updated_out [0:SYSTOLIC_ARRAY_WIDTH - 1];
	wire grad_descent_done_out [0:SYSTOLIC_ARRAY_WIDTH - 1];
	reg [15:0] grad_descent_ptr;
	reg grad_bias_or_weight;
	genvar _gv_i_1;
	generate
		for (_gv_i_1 = 0; _gv_i_1 < SYSTOLIC_ARRAY_WIDTH; _gv_i_1 = _gv_i_1 + 1) begin : gradient_descent_gen
			localparam i = _gv_i_1;
			gradient_descent gradient_descent_inst(
				.clk(clk),
				.rst(rst),
				.lr_in(learning_rate_in),
				.grad_in(ub_wr_data_in[((SYSTOLIC_ARRAY_WIDTH - 1) - i) * 16+:16]),
				.value_old_in(value_old_in[i]),
				.grad_descent_valid_in(grad_descent_valid_in[i]),
				.grad_bias_or_weight(grad_bias_or_weight),
				.value_updated_out(value_updated_out[i]),
				.grad_descent_done_out(grad_descent_done_out[i])
			);
		end
	endgenerate
	assign ub_rd_input_data_out_0 = ub_rd_input_data_out[0];
	assign ub_rd_input_data_out_1 = ub_rd_input_data_out[1];
	assign ub_rd_input_valid_out_0 = ub_rd_input_valid_out[0];
	assign ub_rd_input_valid_out_1 = ub_rd_input_valid_out[1];
	assign ub_rd_weight_data_out_0 = ub_rd_weight_data_out[0];
	assign ub_rd_weight_data_out_1 = ub_rd_weight_data_out[1];
	assign ub_rd_weight_valid_out_0 = ub_rd_weight_valid_out[0];
	assign ub_rd_weight_valid_out_1 = ub_rd_weight_valid_out[1];
	assign ub_rd_bias_data_out_0 = ub_rd_bias_data_out[0];
	assign ub_rd_bias_data_out_1 = ub_rd_bias_data_out[1];
	assign ub_rd_Y_data_out_0 = ub_rd_Y_data_out[0];
	assign ub_rd_Y_data_out_1 = ub_rd_Y_data_out[1];
	assign ub_rd_H_data_out_0 = ub_rd_H_data_out[0];
	assign ub_rd_H_data_out_1 = ub_rd_H_data_out[1];
	always @(*) begin
		if (_sv2v_0)
			;
		if (ub_rd_start_in)
			case (ub_ptr_select)
				0: begin
					rd_input_transpose = ub_rd_transpose;
					rd_input_ptr = ub_rd_addr_in;
					if (ub_rd_transpose) begin
						rd_input_row_size = ub_rd_col_size;
						rd_input_col_size = ub_rd_row_size;
					end
					else begin
						rd_input_row_size = ub_rd_row_size;
						rd_input_col_size = ub_rd_col_size;
					end
					rd_input_time_counter = 1'sb0;
				end
				1: begin
					rd_weight_transpose = ub_rd_transpose;
					if (ub_rd_transpose) begin
						rd_weight_row_size = ub_rd_col_size;
						rd_weight_col_size = ub_rd_row_size;
						rd_weight_ptr = (ub_rd_addr_in + ub_rd_col_size) - 1;
						ub_rd_col_size_out = ub_rd_row_size;
					end
					else begin
						rd_weight_row_size = ub_rd_row_size;
						rd_weight_col_size = ub_rd_col_size;
						rd_weight_ptr = (ub_rd_addr_in + (ub_rd_row_size * ub_rd_col_size)) - ub_rd_col_size;
						ub_rd_col_size_out = ub_rd_col_size;
					end
					rd_weight_skip_size = ub_rd_col_size + 1;
					rd_weight_time_counter = 1'sb0;
					ub_rd_col_size_valid_out = 1'b1;
				end
				2: begin
					rd_bias_ptr = ub_rd_addr_in;
					rd_bias_row_size = ub_rd_row_size;
					rd_bias_col_size = ub_rd_col_size;
					rd_bias_time_counter = 1'sb0;
				end
				3: begin
					rd_Y_ptr = ub_rd_addr_in;
					rd_Y_row_size = ub_rd_row_size;
					rd_Y_col_size = ub_rd_col_size;
					rd_Y_time_counter = 1'sb0;
				end
				4: begin
					rd_H_ptr = ub_rd_addr_in;
					rd_H_row_size = ub_rd_row_size;
					rd_H_col_size = ub_rd_col_size;
					rd_H_time_counter = 1'sb0;
				end
				5: begin
					rd_grad_bias_ptr = ub_rd_addr_in;
					rd_grad_bias_row_size = ub_rd_row_size;
					rd_grad_bias_col_size = ub_rd_col_size;
					rd_grad_bias_time_counter = 1'sb0;
					grad_bias_or_weight = 1'b0;
					grad_descent_ptr = ub_rd_addr_in;
				end
				6: begin
					rd_grad_weight_ptr = ub_rd_addr_in;
					rd_grad_weight_row_size = ub_rd_row_size;
					rd_grad_weight_col_size = ub_rd_col_size;
					rd_grad_weight_time_counter = 1'sb0;
					grad_bias_or_weight = 1'b1;
					grad_descent_ptr = ub_rd_addr_in;
				end
			endcase
		else begin
			ub_rd_col_size_out = 0;
			ub_rd_col_size_valid_out = 1'b0;
		end
	end
	always @(*) begin
		if (_sv2v_0)
			;
		if ((rd_grad_bias_time_counter < (rd_grad_bias_row_size + rd_grad_bias_col_size)) || (rd_grad_weight_time_counter < (rd_grad_weight_row_size + rd_grad_weight_col_size))) begin : sv2v_autoblock_1
			reg signed [31:0] i;
			for (i = 0; i < SYSTOLIC_ARRAY_WIDTH; i = i + 1)
				grad_descent_valid_in[i] = ub_wr_valid_in[i];
		end
		else begin : sv2v_autoblock_2
			reg signed [31:0] i;
			for (i = 0; i < SYSTOLIC_ARRAY_WIDTH; i = i + 1)
				grad_descent_valid_in[i] = 1'b0;
		end
	end
	always @(posedge clk or posedge rst) begin
		begin : sv2v_autoblock_3
			reg signed [31:0] i;
			for (i = 0; i < UNIFIED_BUFFER_WIDTH; i = i + 1)
				$dumpvars(0, ub_memory[i]);
		end
		begin : sv2v_autoblock_4
			reg signed [31:0] i;
			for (i = 0; i < SYSTOLIC_ARRAY_WIDTH; i = i + 1)
				begin
					$dumpvars(0, ub_wr_data_in[((SYSTOLIC_ARRAY_WIDTH - 1) - i) * 16+:16]);
					$dumpvars(0, ub_wr_valid_in[i]);
					$dumpvars(0, ub_rd_input_data_out[i]);
					$dumpvars(0, ub_rd_input_valid_out[i]);
					$dumpvars(0, ub_rd_weight_data_out[i]);
					$dumpvars(0, ub_rd_weight_valid_out[i]);
					$dumpvars(0, ub_rd_bias_data_out[i]);
					$dumpvars(0, ub_rd_Y_data_out[i]);
					$dumpvars(0, ub_rd_H_data_out[i]);
					$dumpvars(0, value_old_in[i]);
					$dumpvars(0, grad_descent_valid_in[i]);
					$dumpvars(0, grad_descent_done_out[i]);
					$dumpvars(0, value_updated_out[i]);
				end
		end
		if (rst) begin
			begin : sv2v_autoblock_5
				reg signed [31:0] i;
				for (i = 0; i < UNIFIED_BUFFER_WIDTH; i = i + 1)
					ub_memory[i] <= 1'sb0;
			end
			begin : sv2v_autoblock_6
				reg signed [31:0] i;
				for (i = 0; i < SYSTOLIC_ARRAY_WIDTH; i = i + 1)
					begin
						ub_rd_input_data_out[i] <= 1'sb0;
						ub_rd_input_valid_out[i] <= 1'sb0;
						ub_rd_weight_data_out[i] <= 1'sb0;
						ub_rd_weight_valid_out[i] <= 1'sb0;
						ub_rd_bias_data_out[i] <= 1'sb0;
						ub_rd_Y_data_out[i] <= 1'sb0;
						ub_rd_H_data_out[i] <= 1'sb0;
						value_old_in[i] <= 1'sb0;
						grad_descent_valid_in[i] <= 1'sb0;
					end
			end
			wr_ptr <= 1'sb0;
			rd_input_ptr <= 1'sb0;
			rd_input_row_size <= 1'sb0;
			rd_input_col_size <= 1'sb0;
			rd_input_time_counter <= 1'sb0;
			rd_input_transpose <= 1'sb0;
			rd_weight_ptr <= 1'sb0;
			rd_weight_row_size <= 1'sb0;
			rd_weight_col_size <= 1'sb0;
			rd_weight_time_counter <= 1'sb0;
			rd_weight_transpose <= 1'sb0;
			rd_bias_ptr <= 1'sb0;
			rd_bias_row_size <= 1'sb0;
			rd_bias_col_size <= 1'sb0;
			rd_bias_time_counter <= 1'sb0;
			rd_Y_ptr <= 1'sb0;
			rd_Y_row_size <= 1'sb0;
			rd_Y_col_size <= 1'sb0;
			rd_Y_time_counter <= 1'sb0;
			rd_H_ptr <= 1'sb0;
			rd_H_row_size <= 1'sb0;
			rd_H_col_size <= 1'sb0;
			rd_H_time_counter <= 1'sb0;
			rd_grad_bias_ptr <= 1'sb0;
			rd_grad_bias_row_size <= 1'sb0;
			rd_grad_bias_col_size <= 1'sb0;
			rd_grad_bias_time_counter <= 1'sb0;
			rd_grad_weight_ptr <= 1'sb0;
			rd_grad_weight_row_size <= 1'sb0;
			rd_grad_weight_col_size <= 1'sb0;
			rd_grad_weight_time_counter <= 1'sb0;
		end
		else begin
			begin : sv2v_autoblock_7
				reg signed [31:0] i;
				for (i = SYSTOLIC_ARRAY_WIDTH - 1; i >= 0; i = i - 1)
					if (ub_wr_valid_in[i]) begin
						ub_memory[wr_ptr] <= ub_wr_data_in[((SYSTOLIC_ARRAY_WIDTH - 1) - i) * 16+:16];
						wr_ptr = wr_ptr + 1;
					end
					else if (ub_wr_host_valid_in[i]) begin
						ub_memory[wr_ptr] <= ub_wr_host_data_in[((SYSTOLIC_ARRAY_WIDTH - 1) - i) * 16+:16];
						wr_ptr = wr_ptr + 1;
					end
			end
			if (grad_bias_or_weight) begin : sv2v_autoblock_8
				reg signed [31:0] i;
				for (i = SYSTOLIC_ARRAY_WIDTH - 1; i >= 0; i = i - 1)
					if (grad_descent_done_out[i]) begin
						ub_memory[grad_descent_ptr] <= value_updated_out[i];
						grad_descent_ptr = grad_descent_ptr + 1;
					end
			end
			else begin : sv2v_autoblock_9
				reg signed [31:0] i;
				for (i = SYSTOLIC_ARRAY_WIDTH - 1; i >= 0; i = i - 1)
					if (grad_descent_done_out[i])
						ub_memory[grad_descent_ptr + i] <= value_updated_out[i];
			end
			if ((rd_input_time_counter + 1) < (rd_input_row_size + rd_input_col_size)) begin
				if (rd_input_transpose) begin : sv2v_autoblock_10
					reg signed [31:0] i;
					for (i = 0; i < SYSTOLIC_ARRAY_WIDTH; i = i + 1)
						if (((rd_input_time_counter >= i) && (rd_input_time_counter < (rd_input_row_size + i))) && (i < rd_input_col_size)) begin
							ub_rd_input_valid_out[i] <= 1'b1;
							ub_rd_input_data_out[i] <= ub_memory[rd_input_ptr];
							rd_input_ptr = rd_input_ptr + 1;
						end
						else begin
							ub_rd_input_valid_out[i] <= 1'b0;
							ub_rd_input_data_out[i] <= 1'sb0;
						end
				end
				else begin : sv2v_autoblock_11
					reg signed [31:0] i;
					for (i = SYSTOLIC_ARRAY_WIDTH - 1; i >= 0; i = i - 1)
						if (((rd_input_time_counter >= i) && (rd_input_time_counter < (rd_input_row_size + i))) && (i < rd_input_col_size)) begin
							ub_rd_input_valid_out[i] <= 1'b1;
							ub_rd_input_data_out[i] <= ub_memory[rd_input_ptr];
							rd_input_ptr = rd_input_ptr + 1;
						end
						else begin
							ub_rd_input_valid_out[i] <= 1'b0;
							ub_rd_input_data_out[i] <= 1'sb0;
						end
				end
				rd_input_time_counter <= rd_input_time_counter + 1;
			end
			else begin
				rd_input_ptr <= 0;
				rd_input_row_size <= 0;
				rd_input_col_size <= 0;
				rd_input_time_counter <= 1'sb0;
				begin : sv2v_autoblock_12
					reg signed [31:0] i;
					for (i = 0; i < SYSTOLIC_ARRAY_WIDTH; i = i + 1)
						begin
							ub_rd_input_valid_out[i] <= 1'b0;
							ub_rd_input_data_out[i] <= 1'sb0;
						end
				end
			end
			if ((rd_weight_time_counter + 1) < (rd_weight_row_size + rd_weight_col_size)) begin
				if (rd_weight_transpose) begin
					begin : sv2v_autoblock_13
						reg signed [31:0] i;
						for (i = 0; i < SYSTOLIC_ARRAY_WIDTH; i = i + 1)
							if (((rd_weight_time_counter >= i) && (rd_weight_time_counter < (rd_weight_row_size + i))) && (i < rd_weight_col_size)) begin
								ub_rd_weight_valid_out[i] <= 1'b1;
								ub_rd_weight_data_out[i] <= ub_memory[rd_weight_ptr];
								rd_weight_ptr = rd_weight_ptr + rd_weight_skip_size;
							end
							else begin
								ub_rd_weight_valid_out[i] <= 0;
								ub_rd_weight_data_out[i] <= 1'sb0;
							end
					end
					rd_weight_ptr = (rd_weight_ptr - rd_weight_skip_size) - 1;
				end
				else begin
					begin : sv2v_autoblock_14
						reg signed [31:0] i;
						for (i = SYSTOLIC_ARRAY_WIDTH - 1; i >= 0; i = i - 1)
							if (((rd_weight_time_counter >= i) && (rd_weight_time_counter < (rd_weight_row_size + i))) && (i < rd_weight_col_size)) begin
								ub_rd_weight_valid_out[i] <= 1'b1;
								ub_rd_weight_data_out[i] <= ub_memory[rd_weight_ptr];
								rd_weight_ptr = rd_weight_ptr - rd_weight_skip_size;
							end
							else begin
								ub_rd_weight_valid_out[i] <= 0;
								ub_rd_weight_data_out[i] <= 1'sb0;
							end
					end
					rd_weight_ptr = (rd_weight_ptr + rd_weight_skip_size) + 1;
				end
				rd_weight_time_counter <= rd_weight_time_counter + 1;
			end
			else begin
				rd_weight_ptr <= 0;
				rd_weight_row_size <= 0;
				rd_weight_col_size <= 0;
				rd_weight_time_counter <= 1'sb0;
				begin : sv2v_autoblock_15
					reg signed [31:0] i;
					for (i = 0; i < SYSTOLIC_ARRAY_WIDTH; i = i + 1)
						begin
							ub_rd_weight_valid_out[i] <= 0;
							ub_rd_weight_data_out[i] <= 1'sb0;
						end
				end
			end
			if ((rd_bias_time_counter + 1) < (rd_bias_row_size + rd_bias_col_size)) begin
				begin : sv2v_autoblock_16
					reg signed [31:0] i;
					for (i = 0; i < SYSTOLIC_ARRAY_WIDTH; i = i + 1)
						if (((rd_bias_time_counter >= i) && (rd_bias_time_counter < (rd_bias_row_size + i))) && (i < rd_bias_col_size))
							ub_rd_bias_data_out[i] <= ub_memory[rd_bias_ptr + i];
						else
							ub_rd_bias_data_out[i] <= 1'sb0;
				end
				rd_bias_time_counter <= rd_bias_time_counter + 1;
			end
			else begin
				rd_bias_ptr <= 0;
				rd_bias_row_size <= 0;
				rd_bias_col_size <= 0;
				rd_bias_time_counter <= 1'sb0;
				begin : sv2v_autoblock_17
					reg signed [31:0] i;
					for (i = 0; i < SYSTOLIC_ARRAY_WIDTH; i = i + 1)
						ub_rd_bias_data_out[i] <= 1'sb0;
				end
			end
			if ((rd_Y_time_counter + 1) < (rd_Y_row_size + rd_Y_col_size)) begin
				begin : sv2v_autoblock_18
					reg signed [31:0] i;
					for (i = SYSTOLIC_ARRAY_WIDTH - 1; i >= 0; i = i - 1)
						if (((rd_Y_time_counter >= i) && (rd_Y_time_counter < (rd_Y_row_size + i))) && (i < rd_Y_col_size)) begin
							ub_rd_Y_data_out[i] <= ub_memory[rd_Y_ptr];
							rd_Y_ptr = rd_Y_ptr + 1;
						end
						else
							ub_rd_Y_data_out[i] <= 1'sb0;
				end
				rd_Y_time_counter <= rd_Y_time_counter + 1;
			end
			else begin
				rd_Y_ptr <= 0;
				rd_Y_row_size <= 0;
				rd_Y_col_size <= 0;
				rd_Y_time_counter <= 1'sb0;
				begin : sv2v_autoblock_19
					reg signed [31:0] i;
					for (i = 0; i < SYSTOLIC_ARRAY_WIDTH; i = i + 1)
						ub_rd_Y_data_out[i] <= 1'sb0;
				end
			end
			if ((rd_H_time_counter + 1) < (rd_H_row_size + rd_H_col_size)) begin
				begin : sv2v_autoblock_20
					reg signed [31:0] i;
					for (i = SYSTOLIC_ARRAY_WIDTH - 1; i >= 0; i = i - 1)
						if (((rd_H_time_counter >= i) && (rd_H_time_counter < (rd_H_row_size + i))) && (i < rd_H_col_size)) begin
							ub_rd_H_data_out[i] <= ub_memory[rd_H_ptr];
							rd_H_ptr = rd_H_ptr + 1;
						end
						else
							ub_rd_H_data_out[i] <= 1'sb0;
				end
				rd_H_time_counter <= rd_H_time_counter + 1;
			end
			else begin
				rd_H_ptr <= 0;
				rd_H_row_size <= 0;
				rd_H_col_size <= 0;
				rd_H_time_counter <= 1'sb0;
				begin : sv2v_autoblock_21
					reg signed [31:0] i;
					for (i = 0; i < SYSTOLIC_ARRAY_WIDTH; i = i + 1)
						ub_rd_H_data_out[i] <= 1'sb0;
				end
			end
			if ((rd_grad_bias_time_counter + 1) < (rd_grad_bias_row_size + rd_grad_bias_col_size)) begin
				begin : sv2v_autoblock_22
					reg signed [31:0] i;
					for (i = 0; i < SYSTOLIC_ARRAY_WIDTH; i = i + 1)
						if (((rd_grad_bias_time_counter >= i) && (rd_grad_bias_time_counter < (rd_grad_bias_row_size + i))) && (i < rd_grad_bias_col_size))
							value_old_in[i] <= ub_memory[rd_grad_bias_ptr + i];
						else
							value_old_in[i] <= 1'sb0;
				end
				rd_grad_bias_time_counter <= rd_grad_bias_time_counter + 1;
			end
			else if ((rd_grad_weight_time_counter + 1) < (rd_grad_weight_row_size + rd_grad_weight_col_size)) begin
				begin : sv2v_autoblock_23
					reg signed [31:0] i;
					for (i = SYSTOLIC_ARRAY_WIDTH - 1; i >= 0; i = i - 1)
						if (((rd_grad_weight_time_counter >= i) && (rd_grad_weight_time_counter < (rd_grad_weight_row_size + i))) && (i < rd_grad_weight_col_size)) begin
							value_old_in[i] <= ub_memory[rd_grad_weight_ptr];
							rd_grad_weight_ptr = rd_grad_weight_ptr + 1;
						end
						else
							value_old_in[i] <= 1'sb0;
				end
				rd_grad_weight_time_counter <= rd_grad_weight_time_counter + 1;
			end
			else begin
				rd_grad_bias_ptr <= 0;
				rd_grad_bias_row_size <= 0;
				rd_grad_bias_col_size <= 0;
				rd_grad_bias_time_counter <= 1'sb0;
				rd_grad_weight_ptr <= 0;
				rd_grad_weight_row_size <= 0;
				rd_grad_weight_col_size <= 0;
				rd_grad_weight_time_counter <= 1'sb0;
				begin : sv2v_autoblock_24
					reg signed [31:0] i;
					for (i = 0; i < SYSTOLIC_ARRAY_WIDTH; i = i + 1)
						value_old_in[i] <= 1'sb0;
				end
			end
		end
	end
	initial _sv2v_0 = 0;
endmodule
