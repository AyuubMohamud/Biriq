module EX12 (
    input   wire logic                              flush_i,

    input   wire logic [31:0]                       alu_result,
    input   wire logic [4:0]                        alu_rob_id_i,
    input   wire logic                              alu_wb_valid_i,
    input   wire logic [5:0]                        alu_dest_i,
    input   wire logic                              alu_valid_i,
    // update bimodal counters here OR tell control unit to correct exec path

    output  wire logic [31:0]                       p0_we_data,
    output  wire logic [5:0]                        p0_we_dest,
    output  wire logic                              p0_wen,
    // rob
    output  wire logic [4:0]                        rob_id_o,
    output  wire logic                              rob_valid
);
    assign p0_we_data = alu_result;
    assign p0_we_dest = alu_dest_i;
    assign p0_wen = alu_wb_valid_i&!flush_i;
    assign rob_id_o = alu_rob_id_i; assign rob_valid = alu_valid_i&!flush_i;
endmodule
