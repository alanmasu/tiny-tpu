module pe (
	clk,
	rst,
	pe_psum_in,
	pe_weight_in,
	pe_accept_w_in,
	pe_input_in,
	pe_valid_in,
	pe_switch_in,
	pe_enabled,
	pe_psum_out,
	pe_weight_out,
	pe_input_out,
	pe_valid_out,
	pe_switch_out
);
	reg _sv2v_0;
	parameter signed [31:0] DATA_WIDTH = 16;
	input wire clk;
	input wire rst;
	input wire signed [15:0] pe_psum_in;
	input wire signed [15:0] pe_weight_in;
	input wire pe_accept_w_in;
	input wire signed [15:0] pe_input_in;
	input wire pe_valid_in;
	input wire pe_switch_in;
	input wire pe_enabled;
	output reg signed [15:0] pe_psum_out;
	output reg signed [15:0] pe_weight_out;
	output reg signed [15:0] pe_input_out;
	output reg pe_valid_out;
	output reg pe_switch_out;
	wire signed [15:0] mult_out;
	wire signed [15:0] mac_out;
	reg signed [15:0] weight_reg_active;
	reg signed [15:0] weight_reg_inactive;
	fxp_mul mult(
		.ina(pe_input_in),
		.inb(weight_reg_active),
		.out(mult_out),
		.overflow()
	);
	fxp_add adder(
		.ina(mult_out),
		.inb(pe_psum_in),
		.out(mac_out),
		.overflow()
	);
	always @(*) begin
		if (_sv2v_0)
			;
		if (pe_switch_in)
			weight_reg_active = weight_reg_inactive;
	end
	always @(posedge clk or posedge rst)
		if (rst || !pe_enabled) begin
			pe_input_out <= 16'b0000000000000000;
			weight_reg_active <= 16'b0000000000000000;
			weight_reg_inactive <= 16'b0000000000000000;
			pe_valid_out <= 0;
			pe_weight_out <= 16'b0000000000000000;
			pe_switch_out <= 0;
		end
		else begin
			pe_valid_out <= pe_valid_in;
			pe_switch_out <= pe_switch_in;
			if (pe_accept_w_in) begin
				weight_reg_inactive <= pe_weight_in;
				pe_weight_out <= pe_weight_in;
			end
			else
				pe_weight_out <= 0;
			if (pe_valid_in) begin
				pe_input_out <= pe_input_in;
				pe_psum_out <= mac_out;
			end
			else begin
				pe_valid_out <= 0;
				pe_psum_out <= 16'b0000000000000000;
			end
		end
	initial _sv2v_0 = 0;
endmodule
