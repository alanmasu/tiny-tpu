`timescale 1ns/1ps

// 2x2 systolic array
module systolic #(
    parameter int SYSTOLIC_ARRAY_WIDTH = 2
)(
    input logic clk,
    input logic rst,

    // input signals from top of systolic array
    input logic [(16 * SYSTOLIC_ARRAY_WIDTH)-1:0] sys_weight_in,
    input logic [SYSTOLIC_ARRAY_WIDTH-1:0]sys_accept_w,           // accept weight signal propagates only from top to bottom in column
    input logic sys_switch_in,               // switch signal copies weight from shadow buffer to active buffer. propagates from top left to bottom right
    
    // input signals from left side of systolic array
    input logic [(16 * SYSTOLIC_ARRAY_WIDTH)-1:0] sys_data_in,
    input logic sys_start,
    input logic [$clog2(SYSTOLIC_ARRAY_WIDTH):0] ub_rd_col_size_in,
    input logic ub_rd_col_size_valid_in,

    // output signals from bottom side of systolic array
    output logic [(16 * SYSTOLIC_ARRAY_WIDTH)-1:0] sys_data_out,
    output wire [SYSTOLIC_ARRAY_WIDTH-1:0] sys_valid_out
);
    // PE interfaces
    pe_if peIfMatrix [(SYSTOLIC_ARRAY_WIDTH**2)-1:0] ();
    

    // PE columns to enable
    logic [SYSTOLIC_ARRAY_WIDTH-1:0] pe_enabled;


    // assign sys_valid_out_x1 = pe_valid_out_21;

    localparam int DATA_WIDTH = (16 * SYSTOLIC_ARRAY_WIDTH);

    logic [15:0] sys_weight_in_arr[0:DATA_WIDTH - 1];
    logic [15:0] sys_psum_in_arr[0:DATA_WIDTH - 1];
    logic [15:0] sys_data_in_arr[0:DATA_WIDTH - 1];
    logic [15:0] sys_psum_out_arr[0:DATA_WIDTH - 1];

    logic pe_valid_in_arr [0:SYSTOLIC_ARRAY_WIDTH - 1];

    `define toRCFormat(R, C) ((R) * SYSTOLIC_ARRAY_WIDTH + (C))

    
    generate 
        for(genvar row = 0; row < SYSTOLIC_ARRAY_WIDTH; row++) begin : pe_rows
            for (genvar col = 0; col < SYSTOLIC_ARRAY_WIDTH; col++) begin : pe_cols
                if (row == 0) begin // first row
                    if (col == 0) begin // first row and first column
                        pe pe_inst(
                            .clk(clk),
                            .rst(rst),

                            // North INPUT wires of PE
                            .pe_psum_in( '0 ),
                            .pe_weight_in( sys_weight_in_arr[col] ),
                            .pe_accept_w_in( sys_accept_w[col] ),
                            // West INPUT wires of PE
                            .pe_input_in( sys_data_in_arr[row] ),
                            .pe_valid_in( sys_start ),
                            .pe_switch_in( sys_switch_in ),
                            .pe_enabled(pe_enabled[col]),

                            // South OUTPUT wires of the PE
                            .pe_psum_out( peIfMatrix[`toRCFormat(row, col)].pe_psum_out ),
                            .pe_weight_out( peIfMatrix[`toRCFormat(row, col)].pe_weight_out ), 
                            .pe_accept_w_out( peIfMatrix[`toRCFormat(row, col)].pe_accept_w_out ),

                            // East OUTPUT wires of the PE
                            .pe_input_out( peIfMatrix[`toRCFormat(row, col)].pe_input_out ),
                            .pe_valid_out( peIfMatrix[`toRCFormat(row, col)].pe_valid_out ),
                            .pe_switch_out( peIfMatrix[`toRCFormat(row, col)].pe_switch_out )
                        );
                    end else begin // first row but not first column
                        pe pe_inst(
                            .clk(clk),
                            .rst(rst),

                            // North INPUT wires of PE
                            .pe_psum_in( '0 ),
                            .pe_weight_in( sys_weight_in_arr[col] ),
                            .pe_accept_w_in( sys_accept_w[col] ),
                            // West INPUT wires of PE
                            .pe_input_in( peIfMatrix[`toRCFormat(row, col-1)].pe_input_out ),
                            .pe_valid_in( peIfMatrix[`toRCFormat(row, col-1)].pe_valid_out ),
                            .pe_switch_in( peIfMatrix[`toRCFormat(row, col-1)].pe_switch_out ),
                            .pe_enabled(pe_enabled[col]),
                            // South OUTPUT wires of the PE
                            .pe_psum_out( peIfMatrix[`toRCFormat(row, col)].pe_psum_out ),
                            .pe_weight_out( peIfMatrix[`toRCFormat(row, col)].pe_weight_out ), 
                            .pe_accept_w_out( peIfMatrix[`toRCFormat(row, col)].pe_accept_w_out ),
                            // East OUTPUT wires of the PE
                            .pe_input_out( peIfMatrix[`toRCFormat(row, col)].pe_input_out ),
                            .pe_valid_out( peIfMatrix[`toRCFormat(row, col)].pe_valid_out ),
                            .pe_switch_out( peIfMatrix[`toRCFormat(row, col)].pe_switch_out )
                        );
                    end
                end else if (row == SYSTOLIC_ARRAY_WIDTH - 1) begin  // last row first column
                    if (col == 0) begin
                        pe pe_inst(
                            .clk(clk),
                            .rst(rst),

                            // North INPUT wires of PE
                            .pe_psum_in( peIfMatrix[`toRCFormat(row-1, col)].pe_psum_out ),
                            .pe_weight_in( peIfMatrix[`toRCFormat(row-1, col)].pe_weight_out ),
                            .pe_accept_w_in( peIfMatrix[`toRCFormat(row-1, col)].pe_accept_w_out ),
                            // West INPUT wires of PE
                            .pe_input_in( sys_data_in_arr[row] ),
                            .pe_valid_in( peIfMatrix[`toRCFormat(row-1, col)].pe_valid_out ),
                            .pe_switch_in( peIfMatrix[`toRCFormat(row-1, col)].pe_switch_out ),
                            .pe_enabled(pe_enabled[col]),
                            // South OUTPUT wires of the PE
                            .pe_psum_out( sys_psum_out_arr[col] )
                        );
                    end else begin
                        pe pe_inst(
                            .clk(clk),
                            .rst(rst),

                            // North INPUT wires of PE
                            .pe_psum_in( peIfMatrix[`toRCFormat(row-1, col)].pe_psum_out ),
                            .pe_weight_in( peIfMatrix[`toRCFormat(row-1, col)].pe_weight_out ),
                            .pe_accept_w_in( peIfMatrix[`toRCFormat(row-1, col)].pe_accept_w_out ),
                            // West INPUT wires of PE
                            .pe_input_in( peIfMatrix[`toRCFormat(row, col-1)].pe_input_out ),
                            .pe_valid_in( peIfMatrix[`toRCFormat(row, col-1)].pe_valid_out ),
                            .pe_switch_in( peIfMatrix[`toRCFormat(row, col-1)].pe_switch_out ),
                            .pe_enabled(pe_enabled[col]),
                            // South OUTPUT wires of the PE
                            .pe_psum_out( sys_psum_out_arr[col] )
                        );
                    end
                end else begin // middle rows
                    if (col == 0) begin // first column of middle rows
                        pe pe_inst(
                            .clk(clk),
                            .rst(rst),

                            // North INPUT wires of PE
                            .pe_psum_in( peIfMatrix[`toRCFormat(row-1, col)].pe_psum_out ),
                            .pe_weight_in( peIfMatrix[`toRCFormat(row-1, col)].pe_weight_out ),
                            .pe_accept_w_in( peIfMatrix[`toRCFormat(row-1, col)].pe_accept_w_out ),
                            // West INPUT wires of PE
                            .pe_input_in( sys_data_in_arr[row] ),
                            .pe_valid_in( peIfMatrix[`toRCFormat(row-1, col)].pe_valid_out ),
                            .pe_switch_in( peIfMatrix[`toRCFormat(row-1, col)].pe_switch_out ),
                            .pe_enabled(pe_enabled[col]),
                            // South OUTPUT wires of the PE
                            .pe_psum_out( peIfMatrix[`toRCFormat(row, col)].pe_psum_out ),
                            .pe_weight_out( peIfMatrix[`toRCFormat(row, col)].pe_weight_out ), 
                            .pe_accept_w_out( peIfMatrix[`toRCFormat(row, col)].pe_accept_w_out ),
                            // East OUTPUT wires of the PE
                            .pe_input_out( peIfMatrix[`toRCFormat(row, col)].pe_input_out ),
                            .pe_valid_out( peIfMatrix[`toRCFormat(row, col)].pe_valid_out ),
                            .pe_switch_out( peIfMatrix[`toRCFormat(row, col)].pe_switch_out )
                        );
                    end else begin // middle rows not first column
                        pe pe_inst(
                            .clk(clk),
                            .rst(rst),

                            // North INPUT wires of PE
                            .pe_psum_in( peIfMatrix[`toRCFormat(row-1, col)].pe_psum_out ),
                            .pe_weight_in( peIfMatrix[`toRCFormat(row-1, col)].pe_weight_out ),
                            .pe_accept_w_in( peIfMatrix[`toRCFormat(row-1, col)].pe_accept_w_out ),
                            // West INPUT wires of PE
                            .pe_input_in( peIfMatrix[`toRCFormat(row, col-1)].pe_input_out ),
                            .pe_valid_in( peIfMatrix[`toRCFormat(row, col-1)].pe_valid_out ),
                            .pe_switch_in( peIfMatrix[`toRCFormat(row, col-1)].pe_switch_out ),
                            .pe_enabled(pe_enabled[col]),
                            // South OUTPUT wires of the PE
                            .pe_psum_out( peIfMatrix[`toRCFormat(row, col)].pe_psum_out ),
                            .pe_weight_out( peIfMatrix[`toRCFormat(row, col)].pe_weight_out ), 
                            .pe_accept_w_out( peIfMatrix[`toRCFormat(row, col)].pe_accept_w_out ),
                            // East OUTPUT wires of the PE
                            .pe_input_out( peIfMatrix[`toRCFormat(row, col)].pe_input_out ),
                            .pe_valid_out( peIfMatrix[`toRCFormat(row, col)].pe_valid_out ),
                            .pe_switch_out( peIfMatrix[`toRCFormat(row, col)].pe_switch_out )
                        );
                    end
                end
            end 
        end 
        
        // Array population logic
        for (genvar i = 0; i < DATA_WIDTH; i++) begin : input_assignment
            assign sys_weight_in_arr[i] = sys_weight_in[(16*i)+15 -: 16];
            assign sys_data_in_arr[i] = sys_data_in[(16*i)+15 -: 16];

            //Output assignment
            assign sys_data_out[(16*i)+15 -: 16] = sys_psum_out_arr[i];
        end
    endgenerate


    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            pe_enabled <= '0;
        end else begin
            if(ub_rd_col_size_valid_in) begin
                pe_enabled <= (1 << ub_rd_col_size_in) - 1;
            end
        end
    end

endmodule