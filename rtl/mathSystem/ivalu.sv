module ivalu (
    input   wire logic              core_clock_i,
    input   wire logic              core_reset_i,

    input   wire logic [31:0]       a,
    input   wire logic [31:0]       b,
    input   wire logic [6:0]        op,
    input   wire logic [4:0]        rob_i,    
    input   wire logic [5:0]        dest_i,
    input   wire logic              valid_i,
    output       logic [31:0]       result_o,
    output       logic [4:0]        rob_o,
    output       logic              wb_valid_o,
    output       logic [5:0]        dest_o,
    output       logic              valid_o
);

    wire [31:0] vadder;
    wire [31:0] vmisc;
    wire [31:0] vcmper;
    ivadder vadder0 (a, b, op[2:0], op[6], vadder);
    ivcmper vcmper0 (a, b, op[3:0], op[6], vcmper);
    ivmisc ivmisc0 (a, b, op[1:0], op[6], vmisc);

    always_ff @(posedge core_clock_i) begin
        case (op[5:4])
            2'b00: result_o <= vadder;
            2'b01: result_o <= vcmper;
            2'b10: result_o <= vmisc;
        endcase
        valid_o <= !core_reset_i&valid_i;
        dest_o <= dest_i;
        wb_valid_o <= !core_reset_i&valid_i&(dest_i!=0);
        rob_o <= rob_i;
    end
endmodule
