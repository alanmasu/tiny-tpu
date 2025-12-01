`default_nettype none
module leaky_relu_derivative_child (
	clk,
	rst,
	lr_d_valid_in,
	lr_d_data_in,
	lr_leak_factor_in,
	lr_d_H_data_in,
	lr_d_valid_out,
	lr_d_data_out
);
	input wire clk;
	input wire rst;
	input wire lr_d_valid_in;
	input wire signed [15:0] lr_d_data_in;
	input wire signed [15:0] lr_leak_factor_in;
	input wire signed [15:0] lr_d_H_data_in;
	output reg lr_d_valid_out;
	output reg signed [15:0] lr_d_data_out;
	wire signed [15:0] mul_out;
	fxp_mul mul_inst(
		.ina(lr_d_data_in),
		.inb(lr_leak_factor_in),
		.out(mul_out)
	);
	always @(posedge clk or posedge rst)
		if (rst) begin
			lr_d_data_out <= 16'b0000000000000000;
			lr_d_valid_out <= 0;
		end
		else begin
			lr_d_valid_out <= lr_d_valid_in;
			if (lr_d_valid_in) begin
				if (lr_d_H_data_in >= 0)
					lr_d_data_out <= lr_d_data_in;
				else
					lr_d_data_out <= mul_out;
			end
			else
				lr_d_data_out <= 16'b0000000000000000;
		end
endmodule
