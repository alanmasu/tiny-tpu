module gradient_descent (
	clk,
	rst,
	lr_in,
	value_old_in,
	grad_in,
	grad_descent_valid_in,
	grad_bias_or_weight,
	value_updated_out,
	grad_descent_done_out
);
	reg _sv2v_0;
	input wire clk;
	input wire rst;
	input wire [15:0] lr_in;
	input wire [15:0] value_old_in;
	input wire [15:0] grad_in;
	input wire grad_descent_valid_in;
	input wire grad_bias_or_weight;
	output reg [15:0] value_updated_out;
	output reg grad_descent_done_out;
	wire [15:0] sub_value_out;
	wire grad_descent_in_reg;
	reg [15:0] sub_in_a;
	wire [15:0] mul_out;
	fxp_mul mul_inst(
		.ina(grad_in),
		.inb(lr_in),
		.out(mul_out),
		.overflow()
	);
	fxp_addsub sub_inst(
		.ina(sub_in_a),
		.inb(mul_out),
		.sub(1'b1),
		.out(sub_value_out),
		.overflow()
	);
	always @(*) begin
		if (_sv2v_0)
			;
		case (grad_bias_or_weight)
			1'b0:
				if (grad_descent_done_out)
					sub_in_a = value_updated_out;
				else
					sub_in_a = value_old_in;
			1'b1: sub_in_a = value_old_in;
		endcase
	end
	always @(posedge clk or posedge rst)
		if (rst) begin
			sub_in_a <= 1'sb0;
			value_updated_out <= 1'sb0;
			grad_descent_done_out <= 1'sb0;
		end
		else begin
			grad_descent_done_out <= grad_descent_valid_in;
			if (grad_descent_valid_in)
				value_updated_out <= sub_value_out;
			else
				value_updated_out <= 1'sb0;
		end
	initial _sv2v_0 = 0;
endmodule
