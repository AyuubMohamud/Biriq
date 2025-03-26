/*
LS pipeline operations:
        0 - Load
        1 - Store
        2 - Atomic
        3 - Load Reserved
        4 - Store Conditional
        5 - Fence
        6 - Cache Block Operations
        7 - CSR Operations
*/
module meu_address_gen (
    input  wire        core_clock_i,
    input  wire        core_flush_i,
    // Register Read <-> AGU
    output wire        agu_busy_o,
    input  wire        agu_vld_i,
    input  wire [ 5:0] agu_rob_i,
    input  wire [ 1:0] agu_sz_i,
    input  wire [ 2:0] agu_op_i,
    input  wire [ 4:0] agu_param_i,
    input  wire [31:0] agu_rs1_i,
    input  wire [31:0] agu_rs2_i,
    input  wire [31:0] agu_imm_i,
    input  wire [ 5:0] agu_dest_i,
    // AGU <-> LS pipeline
    input  wire        lsu_busy_i,
    output wire        lsu_vld_o,
    output wire [ 5:0] lsu_rob_o,
    output wire [ 1:0] lsu_sz_o,
    output wire [ 2:0] lsu_op_o,
    output wire [ 4:0] lsu_param_o,
    output wire [31:0] lsu_addr_o,
    output wire [31:0] lsu_data_o,
    output wire [ 5:0] lsu_dest_o,
    output wire [31:0] lsu_algn_dat_o,
    output wire [ 3:0] lsu_bitmask_o
);
  reg         lsu_vld_q;
  reg  [ 5:0] lsu_rob_q;
  reg  [ 1:0] lsu_sz_q;
  reg  [ 2:0] lsu_op_q;
  reg  [ 4:0] lsu_param_q;
  reg  [31:0] lsu_addr_q;
  reg  [31:0] lsu_data_q;
  reg  [ 5:0] lsu_dest_q;
  reg  [31:0] lsu_sq_align_data_q;
  reg  [ 3:0] lsu_sq_bitmask_q;
  wire [31:0] address_adder;

  initial begin
    lsu_vld_q           = '0;
    lsu_rob_q           = '0;
    lsu_sz_q            = '0;
    lsu_op_q            = '0;
    lsu_param_q         = '0;
    lsu_addr_q          = '0;
    lsu_data_q          = '0;
    lsu_dest_q          = '0;
    lsu_sq_align_data_q = '0;
    lsu_sq_bitmask_q    = '0;
  end

  always_ff @(posedge core_clock_i)
    if (core_flush_i) lsu_vld_q <= 1'b0;
    else if (!agu_busy_o) lsu_vld_q <= agu_vld_i;

  always_ff @(posedge core_clock_i)
    if (!agu_busy_o) begin
      lsu_rob_q <= agu_rob_i;
      lsu_sz_q <= agu_sz_i;
      lsu_op_q <= agu_op_i;
      lsu_param_q <= agu_param_i;
      lsu_addr_q <= address_adder;
      lsu_data_q <= agu_rs2_i;
      lsu_dest_q <= agu_dest_i;
    end

  assign address_adder  = agu_rs1_i + agu_imm_i;
  assign lsu_vld_o      = lsu_vld_q;
  assign lsu_rob_o      = lsu_rob_q;
  assign lsu_sz_o       = lsu_sz_q;
  assign lsu_op_o       = lsu_op_q;
  assign lsu_param_o    = lsu_param_q;
  assign lsu_addr_o     = lsu_addr_q;
  assign lsu_data_o     = lsu_data_q;
  assign lsu_dest_o     = lsu_dest_q;
  assign lsu_algn_dat_o = lsu_sq_align_data_q;
  assign lsu_bitmask_o  = lsu_sq_bitmask_q;
  assign agu_busy_o     = lsu_busy_i;
endmodule
