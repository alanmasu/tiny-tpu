module bias_child (
	clk,
	rst,
	bias_scalar_in,
	bias_Z_valid_out,
	bias_sys_data_in,
	bias_sys_valid_in,
	bias_z_data_out
);
	input wire clk;
	input wire rst;
	input wire signed [15:0] bias_scalar_in;
	output reg bias_Z_valid_out;
	input wire signed [15:0] bias_sys_data_in;
	input wire bias_sys_valid_in;
	output reg signed [15:0] bias_z_data_out;
	wire signed [15:0] z_pre_activation;
	fxp_add add_inst(
		.ina(bias_sys_data_in),
		.inb(bias_scalar_in),
		.out(z_pre_activation)
	);
	always @(posedge clk or posedge rst)
		if (rst) begin
			bias_Z_valid_out <= 1'b0;
			bias_z_data_out <= 16'b0000000000000000;
		end
		else if (bias_sys_valid_in) begin
			bias_Z_valid_out <= 1'b1;
			bias_z_data_out <= z_pre_activation;
		end
		else begin
			bias_Z_valid_out <= 1'b0;
			bias_z_data_out <= 16'b0000000000000000;
		end
endmodule
