module cacheAccess (
    output wire         lsu_busy_o,
    input  wire         lsu_vld_i,
    input  wire  [ 5:0] lsu_rob_i,
    input  wire         lsu_cmo_i,
    input  wire  [ 3:0] lsu_op_i,
    input  wire  [31:0] lsu_addr_i,
    input  wire  [31:0] lsu_data_i,
    input  wire  [ 5:0] lsu_dest_i,
    input  wire  [31:0] lsu_sq_data_i,
    input  wire  [ 3:0] lsu_sq_bm_i,
    input  wire         lq_full_i,
    output logic [31:0] lq_addr_o,
    output logic        lq_cmo_o,
    output logic [ 2:0] lq_ld_type_o,
    output logic [ 5:0] lq_dest_o,
    output logic [ 5:0] lq_rob_o,
    output logic [ 3:0] lq_bm_o,
    output logic        lq_valid_o,
    input  wire         enqueue_full_i,
    output logic [29:0] enqueue_address_o,
    output logic [31:0] enqueue_data_o,
    output logic [ 3:0] enqueue_bm_o,
    output logic        enqueue_io_o,
    output logic        enqueue_en_o,
    output logic [ 4:0] enqueue_rob_o
);

  assign lsu_busy_o = enqueue_full_i | lq_full_i;

  assign enqueue_address_o = lsu_addr_i[31:2];
  assign enqueue_bm_o = lsu_sq_bm_i;
  assign enqueue_data_o = lsu_sq_data_i;
  assign enqueue_io_o = lsu_addr_i[31];
  assign enqueue_en_o = lsu_vld_i & !lq_full_i & lsu_op_i[3] & !lsu_cmo_i;
  assign enqueue_rob_o = lsu_rob_i[4:0];
  assign lq_addr_o = lsu_addr_i;
  assign lq_cmo_o = lsu_cmo_i;
  assign lq_bm_o = lsu_sq_bm_i;
  assign lq_dest_o = lsu_dest_i;
  assign lq_ld_type_o = lsu_op_i[2:0];
  assign lq_rob_o = lsu_rob_i;
  assign lq_valid_o = lsu_vld_i & !enqueue_full_i & (!lsu_op_i[3] | lsu_cmo_i);
endmodule
