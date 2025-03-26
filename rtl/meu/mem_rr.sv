module mem_rr (
    input wire logic core_clock_i,
    input wire logic core_flush_i,

    output wire        meu_busy_i,
    input  wire        meu_vld_o,
    input  wire [ 5:0] meu_rob_o,
    input  wire [ 5:0] meu_type_o,
    input  wire [ 2:0] meu_op_o,
    input  wire [31:0] meu_imm_o,
    input  wire [ 5:0] meu_rs1_o,
    input  wire [ 5:0] meu_rs2_o,
    input  wire [ 5:0] meu_dest_o,

    output wire        lsu_busy_i,
    input  wire        lsu_vld_o,
    input  wire [ 5:0] lsu_rob_o,
    input  wire        lsu_cmo_o,
    input  wire [ 3:0] lsu_op_o,
    input  wire [31:0] lsu_data_o,
    input  wire [31:0] lsu_addr_o,
    input  wire [ 5:0] lsu_dest_o

);
  // At Register Read Stage Register vector raised
  // IXU MC Queue has special logic to handle this scenario using (AV2/AV1)l to schedule, and the register read stage of the subsequent instruction
  // Reads from the register file using the forwarding logic
  // This however writes to RST, which actives
endmodule
