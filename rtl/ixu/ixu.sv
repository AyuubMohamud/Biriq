// SPDX-FileCopyrightText: 2024 Ayuub Mohamud <ayuub.mohamud@outlook.com>
// SPDX-License-Identifier: CERN-OHL-W-2.0

//  -----------------------------------------------------------------------------------------
//  | Copyright (C) Ayuub Mohamud 2024.                                                     |
//  |                                                                                       |
//  | This source describes Open Hardware (RTL) and is licensed under the CERN-OHL-W v2.    |
//  |                                                                                       |
//  | You may redistribute and modify this source and make products using it under          |
//  | the terms of the CERN-OHL-W v2 (https://ohwr.org/cern_ohl_w_v2.txt).                  |
//  |                                                                                       |
//  | This source is distributed WITHOUT ANY EXPRESS OR IMPLIED WARRANTY,                   |
//  | INCLUDING OF MERCHANTABILITY, SATISFACTORY QUALITY AND FITNESS FOR A                  |
//  | PARTICULAR PURPOSE. Please see the CERN-OHL-W v2 for applicable conditions.           |
//  |                                                                                       |
//  | Source location: https://github.com/AyuubMohamud/Biriq                                |
//  |                                                                                       |
//  | As per CERN-OHL-W v2 section 4, should You produce hardware based on this             |
//  | source, You must where practicable maintain the Source Location visible               |
//  | in the same manner as is done within this source.                                     |
//  |                                                                                       |
//  -----------------------------------------------------------------------------------------
module ixu (
    input  wire        core_clock_i,
    input  wire        core_flush_i,
    input  wire [ 6:0] ins0_opcode_i,
    input  wire [ 5:0] ins0_ins_type,
    input  wire        ins0_imm_i,
    input  wire [31:0] ins0_immediate_i,
    input  wire [ 1:0] ins0_hint_i,
    input  wire [ 5:0] ins0_dest_i,
    input  wire        ins0_valid,
    input  wire [ 6:0] ins1_opcode_i,
    input  wire [ 5:0] ins1_ins_type,
    input  wire        ins1_imm_i,
    input  wire [31:0] ins1_immediate_i,
    input  wire [ 5:0] ins1_dest_i,
    input  wire [ 1:0] ins1_hint_i,
    input  wire        ins1_valid,
    input  wire [ 3:0] pack_id,
    input  wire [29:0] rn_pc_i,
    input  wire [ 1:0] rn_bm_pred_i,
    input  wire [ 1:0] rn_btype_i,
    input  wire        rn_btb_vld_i,
    input  wire [29:0] rn_btb_target_i,
    input  wire        rn_btb_way_i,
    input  wire        rn_btb_idx_i,
    input  wire [ 3:0] rn_btb_pack,
    input  wire        rn_btb_wen,
    input  wire [18:0] p0_data_i,
    input  wire        p0_vld_i,
    input  wire        p0_rs1_vld_i,
    input  wire        p0_rs2_vld_i,
    input  wire        p0_rs1_rdy,
    input  wire        p0_rs2_rdy,
    input  wire [18:0] p1_data_i,
    input  wire        p1_vld_i,
    input  wire        p1_rs1_vld_i,
    input  wire        p1_rs2_vld_i,
    input  wire        p1_rs1_rdy,
    input  wire        p1_rs2_rdy,
    output wire        p0_busy_o,
    output wire        p1_busy_o,
    // MemorySystem
    input  wire        eu2_v,
    input  wire [ 5:0] eu2_dest,
    // CIFF bitvector
    output wire        alu0_complete,
    output wire [ 4:0] alu0_rob_id,
    output wire        alu1_complete,
    output wire [ 4:0] alu1_rob_id,
    // RST bitvector
    output wire        alu0_reg_ready,
    output wire [ 5:0] alu0_reg_dest,
    output wire        alu1_reg_ready,
    output wire [ 5:0] alu1_reg_dest,
    // Register file
    output wire [31:0] p0_we_data,
    output wire [ 5:0] p0_we_dest,
    output wire        p0_wen,
    output wire [31:0] p1_we_data,
    output wire [ 5:0] p1_we_dest,
    output wire        p1_wen,
    output wire [ 5:0] ex00_rs1_o,
    output wire [ 5:0] ex00_rs2_o,
    input  wire [31:0] ex00_rs1_data_i,
    input  wire [31:0] ex00_rs2_data_i,
    output wire [ 5:0] ex10_rs1_o,
    output wire [ 5:0] ex10_rs2_o,
    input  wire [31:0] ex10_rs1_data_i,
    input  wire [31:0] ex10_rs2_data_i,
    // Control Unit
    output wire [ 5:0] excp_rob,
    output wire [ 4:0] excp_code,
    output wire        excp_valid,
    output wire [29:0] pmu_btb_vpc_o,
    output wire [29:0] pmu_btb_target_o,
    output wire [ 1:0] pmu_cntr_pred_o,
    output wire        pmu_bnch_tkn_o,
    output wire [ 1:0] pmu_bnch_type_o,
    output wire        pmu_bnch_present_o,
    output wire        pmu_call_affirm_o,
    output wire        pmu_ret_affirm_o,
    // BTB
    output wire        wb_btb_way_o,
    output wire        wb_btb_bm_mod_o
);
  wire [ 6:0] alu0_opcode_o;
  wire [ 5:0] alu0_ins_type;
  wire        alu0_imm_o;
  wire [31:0] alu0_immediate_o;
  wire [ 5:0] alu0_dest_o;
  wire [ 1:0] alu0_hint_o;
  wire [ 4:0] alu0_rob_i;
  wire [ 6:0] alu1_opcode_o;
  wire [ 5:0] alu1_ins_type;
  wire        alu1_imm_o;
  wire [31:0] alu1_immediate_o;
  wire [ 5:0] alu1_dest_o;
  wire [ 1:0] alu1_hint_o;
  wire [ 4:0] alu1_rob_i;
  ixu_iram instructionRAM (
      core_clock_i,
      ins0_opcode_i,
      ins0_ins_type,
      ins0_imm_i,
      ins0_immediate_i,
      ins0_dest_i,
      ins0_hint_i,
      ins0_valid,
      ins1_opcode_i,
      ins1_ins_type,
      ins1_imm_i,
      ins1_immediate_i,
      ins1_dest_i,
      ins1_hint_i,
      ins1_valid,
      pack_id,
      alu0_opcode_o,
      alu0_ins_type,
      alu0_imm_o,
      alu0_immediate_o,
      alu0_dest_o,
      alu0_hint_o,
      alu0_rob_i,
      alu1_opcode_o,
      alu1_ins_type,
      alu1_imm_o,
      alu1_immediate_o,
      alu1_dest_o,
      alu1_hint_o,
      alu1_rob_i
  );
  wire [ 3:0] pack_i = alu0_rob_i[4:1];
  wire [29:0] pc_o;
  wire [ 1:0] bm_pred_o;
  wire [ 1:0] btype_o;
  wire        btb_vld_o;
  wire [29:0] btb_target_o;
  wire        btb_way_o;
  wire        btb_idx_o;
  ixu_binfo branchINFO (
      core_clock_i,
      rn_pc_i,
      rn_bm_pred_i,
      rn_btype_i,
      rn_btb_vld_i,
      rn_btb_target_i,
      rn_btb_way_i,
      rn_btb_idx_i,
      rn_btb_pack,
      rn_btb_wen,
      pack_i,
      pc_o,
      bm_pred_o,
      btype_o,
      btb_vld_o,
      btb_target_o,
      btb_way_o,
      btb_idx_o
  );
  logic        sc_vld;
  logic [17:0] sc_data;
  logic        mc_vld;
  logic [17:0] mc_data;
  wire  [ 5:0] wkp_alu0;
  wire         wkp_alu0_v;
  wire  [ 5:0] wkp_alu1;
  wire         wkp_alu1_v;
  wire         mc_busy;
  ixu_mp_queue uiq0 (
      core_clock_i,
      core_flush_i,
      p0_data_i[17:0],
      p0_data_i[18],
      1'b0,
      p0_vld_i,
      p0_rs1_vld_i,
      p0_rs2_vld_i,
      p0_rs1_rdy,
      p0_rs2_rdy,
      p1_data_i[17:0],
      p1_data_i[18],
      1'b0,
      p1_vld_i,
      p1_rs1_vld_i,
      p1_rs2_vld_i,
      p1_rs1_rdy,
      p1_rs2_rdy,
      p0_busy_o,
      p1_busy_o,
      sc_vld,
      sc_data,
      mc_busy,
      mc_vld,
      mc_data,
      wkp_alu0,
      wkp_alu0_v,
      wkp_alu1,
      wkp_alu1_v,
      eu2_dest,
      eu2_v
  );
  wire ex_fwd, ex2_fwd;
  wire [5:0] ex_dest, ex2_dest;
  wire [31:0] ex_data, ex2_data;
  ixu_sc_pipe ixu_sc_pipe_inst (
      .core_clock_i(core_clock_i),
      .core_flush_i(core_flush_i),
      .data_i(sc_data),
      .valid_i(sc_vld),
      .rs1_o(ex00_rs1_o),
      .rs2_o(ex00_rs2_o),
      .rs1_data_i(ex00_rs1_data_i),
      .rs2_data_i(ex00_rs2_data_i),
      .rob_o(alu0_rob_i),
      .opcode_i(alu0_opcode_o),
      .ins_type(alu0_ins_type),
      .imm_i(alu0_imm_o),
      .immediate_i(alu0_immediate_o),
      .dest_i(alu0_dest_o),
      .hint_i(alu0_hint_o),
      .pc_i(pc_o),
      .bm_pred_i(bm_pred_o),
      .btype_i(btype_o),
      .btb_vld_i(btb_vld_o),
      .btb_target_i(btb_target_o),
      .btb_way_i(btb_way_o),
      .btb_idx_i(btb_idx_o),
      .wakeup_dest(wkp_alu0),
      .wakeup_valid(wkp_alu0_v),
      .ixu_sc_ex_dest(ex_dest),
      .ixu_sc_ex_data(ex_data),
      .ixu_sc_ex_valid(ex_fwd),
      .ixu_sc_wb_dest(p0_we_dest),
      .ixu_sc_wb_data(p0_we_data),
      .ixu_sc_wb_valid(p0_wen),
      .pmu_excp_rob_o(excp_rob),
      .pmu_excp_code_o(excp_code),
      .pmu_excp_valid_o(excp_valid),
      .pmu_btb_vpc_o(pmu_btb_vpc_o),
      .pmu_btb_target_o(pmu_btb_target_o),
      .pmu_cntr_pred_o(pmu_cntr_pred_o),
      .pmu_bnch_tkn_o(pmu_bnch_tkn_o),
      .pmu_bnch_type_o(pmu_bnch_type_o),
      .pmu_call_affirm_o(pmu_call_affirm_o),
      .pmu_ret_affirm_o(pmu_ret_affirm_o),
      .pmu_btb_way_o(wb_btb_way_o),
      .pmu_btb_bm_mod_o(wb_btb_bm_mod_o),
      .pmu_ins_id_o(alu0_rob_id),
      .pmu_ins_valid_o(alu0_complete)
  );
  ixu_mc_pipe ixu_mc_pipe_inst (
      .core_clock_i(core_clock_i),
      .core_flush_i(core_flush_i),
      .data_i(mc_data),
      .valid_i(mc_vld),
      .busy_o(mc_busy),
      .rs1_o(ex10_rs1_o),
      .rs2_o(ex10_rs2_o),
      .rs1_data_i(ex10_rs1_data_i),
      .rs2_data_i(ex10_rs2_data_i),
      .rob_o(alu1_rob_i),
      .opcode_i(alu1_opcode_o),
      .ins_type({1'b0, alu1_ins_type}),
      .imm_i(alu1_imm_o),
      .immediate_i(alu1_immediate_o),
      .dest_i(alu1_dest_o),
      .wakeup_dest(wkp_alu1),
      .wakeup_valid(wkp_alu1_v),
      .ixu_mc_ex_dest(ex2_dest),
      .ixu_mc_ex_data(ex2_data),
      .ixu_mc_ex_valid(ex2_fwd),
      .ixu_mc_wb_dest(p1_we_dest),
      .ixu_mc_wb_data(p1_we_data),
      .ixu_mc_wb_valid(p1_wen),
      .pmu_ins_id_o(alu1_rob_id),
      .pmu_ins_valid_o(alu1_complete)
  );
  assign alu0_reg_ready = wkp_alu0_v;
  assign alu0_reg_dest = wkp_alu0;
  assign alu1_reg_ready = wkp_alu1_v;
  assign alu1_reg_dest = wkp_alu1;
  assign pmu_bnch_present_o = 1'b0;
  // verilator lint_off UNUSED
  wire unused;
  assign unused = |ex_data | |ex_dest | ex_fwd | |ex2_data | |ex2_dest | ex2_fwd | |alu1_hint_o;
  // verilator lint_on UNUSED
endmodule
