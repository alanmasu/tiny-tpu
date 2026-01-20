interface pe_if;
    wire clk;
    wire rst;

    // North INPUT wires of PE
    wire signed [15:0] pe_psum_in; 
    wire signed [15:0] pe_weight_in;
    wire pe_accept_w_in;
    
    // West INPUT wires of PE
    wire signed [15:0] pe_input_in; 
    wire pe_valid_in; 
    wire pe_switch_in; 
    wire pe_enabled;

    // South OUTPUT wires of the PE
    wire signed [15:0] pe_psum_out;
    wire signed [15:0] pe_weight_out;
    wire pe_accept_w_out; 

    // East OUTPUT wires of the PE
    wire signed [15:0] pe_input_out;
    wire pe_valid_out;
    wire pe_switch_out;
endinterface