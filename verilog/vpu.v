module vpu (
	clk,
	rst,
	vpu_data_pathway,
	vpu_data_in_1,
	vpu_data_in_2,
	vpu_valid_in_1,
	vpu_valid_in_2,
	bias_scalar_in_1,
	bias_scalar_in_2,
	lr_leak_factor_in,
	Y_in_1,
	Y_in_2,
	inv_batch_size_times_two_in,
	H_in_1,
	H_in_2,
	vpu_data_out_1,
	vpu_data_out_2,
	vpu_valid_out_1,
	vpu_valid_out_2
);
	input wire clk;
	input wire rst;
	input wire [3:0] vpu_data_pathway;
	input wire signed [15:0] vpu_data_in_1;
	input wire signed [15:0] vpu_data_in_2;
	input wire vpu_valid_in_1;
	input wire vpu_valid_in_2;
	input wire signed [15:0] bias_scalar_in_1;
	input wire signed [15:0] bias_scalar_in_2;
	input wire signed [15:0] lr_leak_factor_in;
	input wire signed [15:0] Y_in_1;
	input wire signed [15:0] Y_in_2;
	input wire signed [15:0] inv_batch_size_times_two_in;
	input wire signed [15:0] H_in_1;
	input wire signed [15:0] H_in_2;
	output reg signed [15:0] vpu_data_out_1;
	output reg signed [15:0] vpu_data_out_2;
	output reg vpu_valid_out_1;
	output reg vpu_valid_out_2;
	reg [15:0] bias_data_1_in;
	reg bias_valid_1_in;
	reg [15:0] bias_data_2_in;
	reg bias_valid_2_in;
	wire [15:0] bias_z_data_out_1;
	wire bias_valid_1_out;
	wire [15:0] bias_z_data_out_2;
	wire bias_valid_2_out;
	reg [15:0] b_to_lr_data_in_1;
	reg b_to_lr_valid_in_1;
	reg [15:0] b_to_lr_data_in_2;
	reg b_to_lr_valid_in_2;
	reg [15:0] lr_data_1_in;
	reg lr_valid_1_in;
	reg [15:0] lr_data_2_in;
	reg lr_valid_2_in;
	wire [15:0] lr_data_1_out;
	wire lr_valid_1_out;
	wire [15:0] lr_data_2_out;
	wire lr_valid_2_out;
	reg [15:0] lr_to_loss_data_in_1;
	reg lr_to_loss_valid_in_1;
	reg [15:0] lr_to_loss_data_in_2;
	reg lr_to_loss_valid_in_2;
	reg [15:0] loss_data_1_in;
	reg loss_valid_1_in;
	reg [15:0] loss_data_2_in;
	reg loss_valid_2_in;
	wire [15:0] loss_data_1_out;
	wire loss_valid_1_out;
	wire [15:0] loss_data_2_out;
	wire loss_valid_2_out;
	reg [15:0] loss_to_lrd_data_in_1;
	reg loss_to_lrd_valid_in_1;
	reg [15:0] loss_to_lrd_data_in_2;
	reg loss_to_lrd_valid_in_2;
	reg [15:0] lr_d_data_1_in;
	reg lr_d_valid_1_in;
	reg [15:0] lr_d_data_2_in;
	reg lr_d_valid_2_in;
	wire [15:0] lr_d_data_1_out;
	wire lr_d_valid_1_out;
	wire [15:0] lr_d_data_2_out;
	wire lr_d_valid_2_out;
	reg [15:0] lr_d_H_in_1;
	reg [15:0] lr_d_H_in_2;
	reg [15:0] last_H_data_1_in;
	reg [15:0] last_H_data_2_in;
	reg [15:0] last_H_data_1_out;
	reg [15:0] last_H_data_2_out;
	bias_parent bias_parent_inst(
		.clk(clk),
		.rst(rst),
		.bias_sys_data_in_1(bias_data_1_in),
		.bias_sys_data_in_2(bias_data_2_in),
		.bias_sys_valid_in_1(bias_valid_1_in),
		.bias_sys_valid_in_2(bias_valid_2_in),
		.bias_scalar_in_1(bias_scalar_in_1),
		.bias_scalar_in_2(bias_scalar_in_2),
		.bias_Z_valid_out_1(bias_valid_1_out),
		.bias_Z_valid_out_2(bias_valid_2_out),
		.bias_z_data_out_1(bias_z_data_out_1),
		.bias_z_data_out_2(bias_z_data_out_2)
	);
	leaky_relu_parent leaky_relu_parent_inst(
		.clk(clk),
		.rst(rst),
		.lr_data_1_in(lr_data_1_in),
		.lr_data_2_in(lr_data_2_in),
		.lr_valid_1_in(lr_valid_1_in),
		.lr_valid_2_in(lr_valid_2_in),
		.lr_leak_factor_in(lr_leak_factor_in),
		.lr_data_1_out(lr_data_1_out),
		.lr_data_2_out(lr_data_2_out),
		.lr_valid_1_out(lr_valid_1_out),
		.lr_valid_2_out(lr_valid_2_out)
	);
	loss_parent loss_parent_inst(
		.clk(clk),
		.rst(rst),
		.H_1_in(loss_data_1_in),
		.H_2_in(loss_data_2_in),
		.valid_1_in(loss_valid_1_in),
		.valid_2_in(loss_valid_2_in),
		.Y_1_in(Y_in_1),
		.Y_2_in(Y_in_2),
		.inv_batch_size_times_two_in(inv_batch_size_times_two_in),
		.gradient_1_out(loss_data_1_out),
		.gradient_2_out(loss_data_2_out),
		.valid_1_out(loss_valid_1_out),
		.valid_2_out(loss_valid_2_out)
	);
	leaky_relu_derivative_parent leaky_relu_derivative_parent_inst(
		.clk(clk),
		.rst(rst),
		.lr_d_data_1_in(lr_d_data_1_in),
		.lr_d_data_2_in(lr_d_data_2_in),
		.lr_d_valid_1_in(lr_d_valid_1_in),
		.lr_d_valid_2_in(lr_d_valid_2_in),
		.lr_d_H_1_in(lr_d_H_in_1),
		.lr_d_H_2_in(lr_d_H_in_2),
		.lr_leak_factor_in(lr_leak_factor_in),
		.lr_d_data_1_out(lr_d_data_1_out),
		.lr_d_data_2_out(lr_d_data_2_out),
		.lr_d_valid_1_out(lr_d_valid_1_out),
		.lr_d_valid_2_out(lr_d_valid_2_out)
	);
	always @(*)
		if (rst) begin
			vpu_data_out_1 = 16'b0000000000000000;
			vpu_data_out_2 = 16'b0000000000000000;
			vpu_valid_out_1 = 1'b0;
			vpu_valid_out_2 = 1'b0;
			bias_data_1_in = 16'b0000000000000000;
			bias_data_2_in = 16'b0000000000000000;
			bias_valid_1_in = 1'b0;
			bias_valid_2_in = 1'b0;
			lr_data_1_in = 16'b0000000000000000;
			lr_data_2_in = 16'b0000000000000000;
			lr_valid_1_in = 1'b0;
			lr_valid_2_in = 1'b0;
			loss_data_1_in = 16'b0000000000000000;
			loss_data_2_in = 16'b0000000000000000;
			loss_valid_1_in = 1'b0;
			loss_valid_2_in = 1'b0;
			lr_d_data_1_in = 16'b0000000000000000;
			lr_d_data_2_in = 16'b0000000000000000;
			lr_d_valid_1_in = 1'b0;
			lr_d_valid_2_in = 1'b0;
		end
		else begin
			if (vpu_data_pathway[3]) begin
				bias_data_1_in = vpu_data_in_1;
				bias_data_2_in = vpu_data_in_2;
				bias_valid_1_in = vpu_valid_in_1;
				bias_valid_2_in = vpu_valid_in_2;
				b_to_lr_data_in_1 = bias_z_data_out_1;
				b_to_lr_data_in_2 = bias_z_data_out_2;
				b_to_lr_valid_in_1 = bias_valid_1_out;
				b_to_lr_valid_in_2 = bias_valid_2_out;
			end
			else begin
				bias_data_1_in = 16'b0000000000000000;
				bias_data_2_in = 16'b0000000000000000;
				bias_valid_1_in = 1'b0;
				bias_valid_2_in = 1'b0;
				b_to_lr_data_in_1 = vpu_data_in_1;
				b_to_lr_data_in_2 = vpu_data_in_2;
				b_to_lr_valid_in_1 = vpu_valid_in_1;
				b_to_lr_valid_in_2 = vpu_valid_in_2;
			end
			if (vpu_data_pathway[2]) begin
				lr_data_1_in = b_to_lr_data_in_1;
				lr_data_2_in = b_to_lr_data_in_2;
				lr_valid_1_in = b_to_lr_valid_in_1;
				lr_valid_2_in = b_to_lr_valid_in_2;
				lr_to_loss_data_in_1 = lr_data_1_out;
				lr_to_loss_data_in_2 = lr_data_2_out;
				lr_to_loss_valid_in_1 = lr_valid_1_out;
				lr_to_loss_valid_in_2 = lr_valid_2_out;
			end
			else begin
				lr_data_1_in = 16'b0000000000000000;
				lr_data_2_in = 16'b0000000000000000;
				lr_valid_1_in = 1'b0;
				lr_valid_2_in = 1'b0;
				lr_to_loss_data_in_1 = b_to_lr_data_in_1;
				lr_to_loss_data_in_2 = b_to_lr_data_in_2;
				lr_to_loss_valid_in_1 = b_to_lr_valid_in_1;
				lr_to_loss_valid_in_2 = b_to_lr_valid_in_2;
			end
			if (vpu_data_pathway[1]) begin
				loss_data_1_in = lr_to_loss_data_in_1;
				loss_data_2_in = lr_to_loss_data_in_2;
				loss_valid_1_in = lr_to_loss_valid_in_1;
				loss_valid_2_in = lr_to_loss_valid_in_2;
				loss_to_lrd_data_in_1 = loss_data_1_out;
				loss_to_lrd_data_in_2 = loss_data_2_out;
				loss_to_lrd_valid_in_1 = loss_valid_1_out;
				loss_to_lrd_valid_in_2 = loss_valid_2_out;
				last_H_data_1_in = lr_data_1_out;
				last_H_data_2_in = lr_data_2_out;
				lr_d_H_in_1 = last_H_data_1_out;
				lr_d_H_in_2 = last_H_data_2_out;
			end
			else begin
				loss_data_1_in = 16'b0000000000000000;
				loss_data_2_in = 16'b0000000000000000;
				loss_valid_1_in = 1'b0;
				loss_valid_2_in = 1'b0;
				loss_to_lrd_data_in_1 = lr_to_loss_data_in_1;
				loss_to_lrd_data_in_2 = lr_to_loss_data_in_2;
				loss_to_lrd_valid_in_1 = lr_to_loss_valid_in_1;
				loss_to_lrd_valid_in_2 = lr_to_loss_valid_in_2;
				lr_d_H_in_1 = H_in_1;
				lr_d_H_in_2 = H_in_2;
			end
			if (vpu_data_pathway[0]) begin
				lr_d_data_1_in = loss_to_lrd_data_in_1;
				lr_d_data_2_in = loss_to_lrd_data_in_2;
				lr_d_valid_1_in = loss_to_lrd_valid_in_1;
				lr_d_valid_2_in = loss_to_lrd_valid_in_2;
				vpu_data_out_1 = lr_d_data_1_out;
				vpu_data_out_2 = lr_d_data_2_out;
				vpu_valid_out_1 = lr_d_valid_1_out;
				vpu_valid_out_2 = lr_d_valid_2_out;
			end
			else begin
				lr_d_data_1_in = loss_to_lrd_data_in_1;
				lr_d_data_2_in = loss_to_lrd_data_in_2;
				lr_d_valid_1_in = loss_to_lrd_valid_in_1;
				lr_d_valid_2_in = loss_to_lrd_valid_in_2;
				vpu_data_out_1 = loss_to_lrd_data_in_1;
				vpu_data_out_2 = loss_to_lrd_data_in_2;
				vpu_valid_out_1 = loss_to_lrd_valid_in_1;
				vpu_valid_out_2 = loss_to_lrd_valid_in_2;
			end
		end
	always @(posedge clk or posedge rst)
		if (rst) begin
			last_H_data_1_in <= 0;
			last_H_data_2_in <= 0;
			last_H_data_1_out <= 0;
			last_H_data_2_out <= 0;
		end
		else if (vpu_data_pathway[1]) begin
			last_H_data_1_out <= last_H_data_1_in;
			last_H_data_2_out <= last_H_data_2_in;
		end
		else begin
			last_H_data_1_out <= 0;
			last_H_data_2_out <= 0;
		end
endmodule
