`default_nettype none
module loss_child (
	clk,
	rst,
	H_in,
	Y_in,
	valid_in,
	inv_batch_size_times_two_in,
	gradient_out,
	valid_out
);
	input wire clk;
	input wire rst;
	input wire signed [15:0] H_in;
	input wire signed [15:0] Y_in;
	input wire valid_in;
	input wire signed [15:0] inv_batch_size_times_two_in;
	output reg signed [15:0] gradient_out;
	output reg valid_out;
	wire signed [15:0] diff_stage1;
	wire signed [15:0] final_gradient;
	fxp_addsub subtractor(
		.ina(H_in),
		.inb(Y_in),
		.sub(1'b1),
		.out(diff_stage1),
		.overflow()
	);
	fxp_mul multiplier(
		.ina(diff_stage1),
		.inb(inv_batch_size_times_two_in),
		.out(final_gradient),
		.overflow()
	);
	always @(posedge clk or posedge rst)
		if (rst) begin
			gradient_out <= 1'sb0;
			valid_out <= 1'sb0;
		end
		else begin
			valid_out <= valid_in;
			gradient_out <= final_gradient;
		end
endmodule
