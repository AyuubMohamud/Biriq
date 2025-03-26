module meu_register_read (
    input  wire        core_clock_i,
    input  wire        core_flush_i,
    // Scheduler <-> MEU pipeline
    output wire        meu_busy_o,
    input  wire        meu_vld_i,
    input  wire [ 5:0] meu_rob_i,
    input  wire        meu_cmo_i,
    input  wire [ 3:0] meu_op_i,
    input  wire [ 5:0] meu_rs1_i,
    input  wire [ 5:0] meu_rs2_i,
    input  wire [31:0] meu_imm_i,
    input  wire [ 5:0] meu_dest_i,
    // MEU pipeline <-> Integer Register File
    output wire [ 5:0] p4_rd_src,
    input  wire [31:0] p4_rd_datas,
    output wire [ 5:0] p5_rd_src,
    input  wire [31:0] p5_rd_datas,
    // MEU pipeline <-> AGU (Executes Load/Store/CSR)
    input  wire        agu_busy_i,
    output wire        agu_vld_o,
    output wire [ 5:0] agu_rob_o,
    output wire [ 1:0] agu_sz_o,
    output wire [ 2:0] agu_op_o,
    output wire [ 4:0] agu_param_o,
    output wire [31:0] agu_rs1_o,
    output wire [31:0] agu_rs2_o,
    output wire [31:0] agu_imm_o,
    output wire [ 5:0] agu_dest_o
);

endmodule
