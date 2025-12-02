module leaky_relu_child (
	clk,
	rst,
	lr_valid_in,
	lr_data_in,
	lr_leak_factor_in,
	lr_data_out,
	lr_valid_out
);
	input wire clk;
	input wire rst;
	input wire lr_valid_in;
	input wire signed [15:0] lr_data_in;
	input wire signed [15:0] lr_leak_factor_in;
	output reg signed [15:0] lr_data_out;
	output reg lr_valid_out;
	wire signed [15:0] mul_out;
	fxp_mul mul_inst(
		.ina(lr_data_in),
		.inb(lr_leak_factor_in),
		.out(mul_out)
	);
	always @(posedge clk or posedge rst)
		if (rst) begin
			lr_data_out <= 16'b0000000000000000;
			lr_valid_out <= 0;
		end
		else if (lr_valid_in) begin
			if (lr_data_in >= 0)
				lr_data_out <= lr_data_in;
			else
				lr_data_out <= mul_out;
			lr_valid_out <= 1;
		end
		else begin
			lr_valid_out <= 0;
			lr_data_out <= 16'b0000000000000000;
		end
endmodule
