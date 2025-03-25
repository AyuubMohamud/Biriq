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
module rename (
    input   wire logic                          cpu_clock_i,
    input   wire logic                          flush_i,
    input   wire logic                          recovery_i,
    input   wire logic                          ins0_port_i,
    input   wire logic                          ins0_dnagn_i,
    input   wire logic [6:0]                    ins0_alu_type_i,
    input   wire logic [6:0]                    ins0_alu_opcode_i,
    input   wire logic                          ins0_alu_imm_i,
    input   wire logic [5:0]                    ins0_ios_type_i,
    input   wire logic [2:0]                    ins0_ios_opcode_i,
    input   wire logic [3:0]                    ins0_special_i,
    input   wire logic [4:0]                    ins0_rs1_i,
    input   wire logic [4:0]                    ins0_rs2_i,
    input   wire logic [4:0]                    ins0_dest_i,
    input   wire logic [31:0]                   ins0_imm_i,
    input   wire logic [2:0]                    ins0_reg_props_i,
    input   wire logic                          ins0_dnr_i,
    input   wire logic                          ins0_mov_elim_i,
    input   wire logic [1:0]                    ins0_hint_i,
    input   wire logic                          ins0_excp_valid_i,
    input   wire logic [3:0]                    ins0_excp_code_i,
    input   wire logic                          ins1_port_i,
    input   wire logic                          ins1_dnagn_i,
    input   wire logic [6:0]                    ins1_alu_type_i,
    input   wire logic [6:0]                    ins1_alu_opcode_i,
    input   wire logic                          ins1_alu_imm_i,
    input   wire logic [5:0]                    ins1_ios_type_i,
    input   wire logic [2:0]                    ins1_ios_opcode_i,
    input   wire logic [3:0]                    ins1_special_i,
    input   wire logic [4:0]                    ins1_rs1_i,
    input   wire logic [4:0]                    ins1_rs2_i,
    input   wire logic [4:0]                    ins1_dest_i,
    input   wire logic [31:0]                   ins1_imm_i,
    input   wire logic [2:0]                    ins1_reg_props_i,
    input   wire logic                          ins1_dnr_i,
    input   wire logic                          ins1_mov_elim_i,
    input   wire logic [1:0]                    ins1_hint_i,
    input   wire logic                          ins1_excp_valid_i,
    input   wire logic [3:0]                    ins1_excp_code_i,
    input   wire logic                          ins1_valid_i,
    input   wire logic [29:0]                   insbundle_pc_i,
    input   wire logic [1:0]                    btb_btype_i,
    input   wire logic [1:0]                    btb_bm_pred_i,
    input   wire logic [29:0]                   btb_target_i,
    input   wire logic                          btb_vld_i,
    input   wire logic                          btb_idx_i,
    input   wire logic                          btb_way_i,
    input   wire logic                          valid_i,
    output  wire logic                          rn_busy_o,
    // retire control unit
    output  wire logic [29:0]                   rcu_packet_pc,
    output  wire logic                          rcu_ins0_is_mov_elim,
    output  wire logic                          rcu_ins0_register_allocated,
    output  wire logic [4:0]                    rcu_ins0_arch_reg,
    output  wire logic [5:0]                    rcu_ins0_old_preg,
    output  wire logic [5:0]                    rcu_ins0_new_preg,
    output  wire logic [3:0]                    rcu_ins0_excp_code,
    output  wire logic                          rcu_ins0_excp_valid,
    output  wire logic [3:0]                    rcu_ins0_special,
    output  wire logic                          rcu_ins0_is_store,
    output  wire logic                          rcu_ins1_is_mov_elim,
    output  wire logic                          rcu_ins1_register_allocated,
    output  wire logic [4:0]                    rcu_ins1_arch_reg,
    output  wire logic [5:0]                    rcu_ins1_old_preg,
    output  wire logic [5:0]                    rcu_ins1_new_preg,
    output  wire logic [3:0]                    rcu_ins1_excp_code,
    output  wire logic                          rcu_ins1_excp_valid,
    output  wire logic [3:0]                    rcu_ins1_special,
    output  wire logic                          rcu_ins1_is_store,
    output  wire logic                          rcu_ins1_valid,
    output  wire logic                          rcu_push_packet,
    input   wire logic                          rcu_busy,
    input   wire logic [4:0]                    rcu_pack,
    input   wire logic [4:0]                    arch_reg0,
    input   wire logic [4:0]                    arch_reg1,
    input   wire logic [5:0]                    phys_reg0,
    input   wire logic [5:0]                    phys_reg1,
    // mathsystem
    output  wire logic [6:0]                    ms_ins0_opcode_o,
    output  wire logic [6:0]                    ms_ins0_ins_type,
    output  wire logic                          ms_ins0_imm_o,
    output  wire logic [31:0]                   ms_ins0_immediate_o,
    output  wire logic [5:0]                    ms_ins0_dest_o,
    output  wire logic [1:0]                    ms_ins0_hint_o,
    output  wire logic                          ms_ins0_valid,
    output  wire logic [6:0]                    ms_ins1_opcode_o,
    output  wire logic [6:0]                    ms_ins1_ins_type,
    output  wire logic                          ms_ins1_imm_o,
    output  wire logic [31:0]                   ms_ins1_immediate_o,
    output  wire logic [5:0]                    ms_ins1_dest_o,
    output  wire logic [1:0]                    ms_ins1_hint_o,
    output  wire logic                          ms_ins1_valid,
    output  wire logic [3:0]                    ms_pack_id,
    output  wire logic [29:0]                   ms_rn_pc_o,
    output  wire logic  [1:0]                   ms_rn_bm_pred_o,
    output  wire logic  [1:0]                   ms_rn_btype_o,
    output  wire logic                          ms_rn_btb_vld_o,
    output  wire logic  [29:0]                  ms_rn_btb_target_o,
    output  wire logic                          ms_rn_btb_way_o,
    output  wire logic                          ms_rn_btb_idx_o,
    output  wire logic [3:0]                    ms_rn_btb_pack,
    output  wire logic                          ms_rn_btb_wen,
    output  wire logic [17:0]                   ms_p0_data_o,
    output  wire logic                          ms_p0_sc_o,
    output  wire logic                          ms_p0_mc_o,
    output  wire logic                          ms_p0_vld_o,
    output  wire logic                          ms_p0_rs1_vld_o,
    output  wire logic                          ms_p0_rs2_vld_o,
    output  wire logic                          ms_p0_rs1_rdy,
    output  wire logic                          ms_p0_rs2_rdy,
    output  wire logic [17:0]                   ms_p1_data_o,
    output  wire logic                          ms_p1_sc_o,
    output  wire logic                          ms_p1_mc_o,
    output  wire logic                          ms_p1_vld_o,
    output  wire logic                          ms_p1_rs1_vld_o,
    output  wire logic                          ms_p1_rs2_vld_o,
    output  wire logic                          ms_p1_rs1_rdy,
    output  wire logic                          ms_p1_rs2_rdy,
    input   wire logic                          ms_p0_busy_i,
    input   wire logic                          ms_p1_busy_i,

    // memory System
    output  wire logic                          memSys_renamer_pkt_vld_o,
    output  wire logic [5:0]                    memSys_pkt0_rs1_o,
    output  wire logic [5:0]                    memSys_pkt0_rs2_o,
    output  wire logic [5:0]                    memSys_pkt0_dest_i,
    output  wire logic [31:0]                   memSys_pkt0_immediate_o,
    output  wire logic [5:0]                    memSys_pkt0_ios_type_o,
    output  wire logic [2:0]                    memSys_pkt0_ios_opcode_o,
    output  wire logic [4:0]                    memSys_pkt0_rob_o,
    output  wire logic                          memSys_pkt0_vld_o,
    output  wire logic [5:0]                    memSys_pkt1_rs1_o,
    output  wire logic [5:0]                    memSys_pkt1_rs2_o,
    output  wire logic [5:0]                    memSys_pkt1_dest_o,
    output  wire logic [31:0]                   memSys_pkt1_immediate_o,
    output  wire logic [5:0]                    memSys_pkt1_ios_type_o,
    output  wire logic [2:0]                    memSys_pkt1_ios_opcode_o,
    output  wire logic                          memSys_pkt1_vld_o,
    input   wire logic                          memSys_full,
    // register status
    output  wire logic [5:0]    p0_vec_indx_o,
    output  wire logic          p0_busy_vld_o,
    output  wire logic [5:0]    p1_vec_indx_o,
    output  wire logic          p1_busy_vld_o,

    output  wire logic [5:0]    r0_vec_indx_o,
    input   wire logic          r0_i,
    output  wire logic [5:0]    r1_vec_indx_o,
    input   wire logic          r1_i,
    output  wire logic [5:0]    r2_vec_indx_o,
    input   wire logic          r2_i,
    output  wire logic [5:0]    r3_vec_indx_o,
    input   wire logic          r3_i,
    // freelist
    // Read side 0
    output  wire logic o_rd0,
    input  wire logic [5:0] i_rd_data0,
    input  wire logic i_empty0,
    // Read side 1
    output  wire logic o_rd1,
    input  wire logic [5:0] i_rd_data1,
    input  wire logic i_empty1
);
    wire busy = i_empty0|i_empty1|memSys_full|(ms_p0_busy_i|ms_p1_busy_i)|rcu_busy;
    wire cyc_valid;
    wire logic                          ins0_port;
    wire logic                          ins0_dnagn;
    wire logic [6:0]                    ins0_alu_type;
    wire logic [6:0]                    ins0_alu_opcode;
    wire logic                          ins0_alu_imm;
    wire logic [5:0]                    ins0_ios_type;
    wire logic [2:0]                    ins0_ios_opcode;
    wire logic [3:0]                    ins0_special;
    wire logic [4:0]                    ins0_rs1;
    wire logic [4:0]                    ins0_rs2;
    wire logic [4:0]                    ins0_dest;
    wire logic [31:0]                   ins0_imm;
    wire logic [2:0]                    ins0_reg_props;
    wire logic                          ins0_dnr;
    wire logic                          ins0_mov_elim;
    wire logic [1:0]                    ins0_hint;
    wire logic                          ins0_excp_valid;
    wire logic [3:0]                    ins0_excp_code;
    wire logic                          ins1_port;
    wire logic                          ins1_dnagn;
    wire logic [6:0]                    ins1_alu_type;
    wire logic [6:0]                    ins1_alu_opcode;
    wire logic                          ins1_alu_imm;
    wire logic [5:0]                    ins1_ios_type;
    wire logic [2:0]                    ins1_ios_opcode;
    wire logic [3:0]                    ins1_special;
    wire logic [4:0]                    ins1_rs1;
    wire logic [4:0]                    ins1_rs2;
    wire logic [4:0]                    ins1_dest;
    wire logic [31:0]                   ins1_imm;
    wire logic [2:0]                    ins1_reg_props;
    wire logic                          ins1_dnr;
    wire logic                          ins1_mov_elim;
    wire logic [1:0]                    ins1_hint;
    wire logic                          ins1_excp_valid;
    wire logic [3:0]                    ins1_excp_code;
    wire logic                          ins1_valid;
    wire logic [29:0]                   insbundle_pc;
    wire logic [1:0]                    btb_btype;
    wire logic [1:0]                    btb_bm_pred;
    wire logic [29:0]                   btb_target;
    wire logic                          btb_vld;
    wire logic                          btb_idx;
    wire logic                          btb_way;
    skdbf #(.DW(246)) rnskid (cpu_clock_i, flush_i, busy, {ins0_port,ins0_dnagn,ins0_alu_type,ins0_alu_opcode,ins0_alu_imm,ins0_ios_type,ins0_ios_opcode,ins0_special,
    ins0_rs1,ins0_rs2,ins0_dest,ins0_imm,ins0_reg_props,ins0_dnr,ins0_mov_elim,ins0_excp_valid,ins0_excp_code,ins1_port,ins1_dnagn,ins1_alu_type,ins1_alu_opcode,ins1_alu_imm,
    ins1_ios_type,ins1_ios_opcode,ins1_special,ins1_rs1,ins1_rs2,ins1_dest,ins1_imm,ins1_reg_props,ins1_dnr,ins1_mov_elim,ins1_excp_valid,ins1_excp_code,ins1_valid,
    insbundle_pc,btb_btype,btb_bm_pred,btb_target,btb_vld,btb_idx,btb_way,ins0_hint,ins1_hint}, cyc_valid, rn_busy_o, {ins0_port_i,ins0_dnagn_i,ins0_alu_type_i,ins0_alu_opcode_i,
    ins0_alu_imm_i,ins0_ios_type_i,ins0_ios_opcode_i,ins0_special_i,ins0_rs1_i,ins0_rs2_i,ins0_dest_i,ins0_imm_i,ins0_reg_props_i,ins0_dnr_i,ins0_mov_elim_i,
    ins0_excp_valid_i,ins0_excp_code_i,ins1_port_i,ins1_dnagn_i,ins1_alu_type_i,ins1_alu_opcode_i,ins1_alu_imm_i,ins1_ios_type_i,ins1_ios_opcode_i,ins1_special_i,
    ins1_rs1_i,ins1_rs2_i,ins1_dest_i,ins1_imm_i,ins1_reg_props_i,ins1_dnr_i,ins1_mov_elim_i,ins1_excp_valid_i,ins1_excp_code_i,ins1_valid_i,insbundle_pc_i,btb_btype_i,
    btb_bm_pred_i,btb_target_i,btb_vld_i,btb_idx_i,btb_way_i,ins0_hint_i,ins1_hint_i}, valid_i);
    wire logic [4:0]    p0_logical_reg = ins0_rs1;
    wire logic [5:0]    p0_phys_reg;
    wire logic [4:0]    p1_logical_reg = ins0_rs2;
    wire logic [5:0]    p1_phys_reg;
    wire logic [4:0]    p2_logical_reg = ins1_rs1;
    wire logic [5:0]    p2_phys_reg;
    wire logic [4:0]    p3_logical_reg = ins1_rs2;
    wire logic [5:0]    p3_phys_reg;
    wire logic [4:0]    p4_logical_reg = ins0_dest;
    wire logic [5:0]    p4_phys_reg;
    wire logic [4:0]    p5_logical_reg = ins1_dest;
    wire logic [5:0]    p5_phys_reg;
    wire logic [4:0]    w0_logical_reg = ins0_dest;
    wire logic [5:0]    w0_phys_reg = ins0_mov_elim ? p0_phys_reg : i_rd_data0;
    wire logic          w0_we = !flush_i&cyc_valid&!busy&(ins0_reg_props[2]|ins0_mov_elim)&!ins0_excp_valid&!(ins0_dest==0);
    wire logic [4:0]    w1_logical_reg = ins1_dest;
    wire logic [5:0]    w1_phys_reg = ins1_mov_elim ? p2_phys_reg : i_rd_data1;
    wire logic          w1_we = !flush_i&cyc_valid&!busy&(ins1_reg_props[2]|ins1_mov_elim)&!ins1_excp_valid&ins1_valid&!(ins1_dest==0);
    srmt speculative_register_remap_table (cpu_clock_i, recovery_i, p0_logical_reg,p0_phys_reg,p1_logical_reg,p1_phys_reg,p2_logical_reg,p2_phys_reg,p3_logical_reg,
    p3_phys_reg,arch_reg0,phys_reg0,arch_reg1,phys_reg1,p4_logical_reg,p4_phys_reg,p5_logical_reg,p5_phys_reg,
    w0_logical_reg,w0_phys_reg,w0_we,w1_logical_reg,w1_phys_reg,w1_we);

    assign ms_ins0_opcode_o = ins0_alu_opcode;
    assign ms_ins0_ins_type = ins0_alu_type;
    assign ms_ins0_imm_o = ins0_alu_imm;
    assign ms_ins0_immediate_o = ins0_imm;
    assign ms_ins0_dest_o = ins0_dest==0 ? 0 : w0_phys_reg;
    assign ms_ins0_hint_o = ins0_hint;
    assign ms_ins0_valid = !ins0_dnagn&!ins0_port&cyc_valid&!flush_i&!busy&!ins0_mov_elim;
    assign ms_ins1_opcode_o = ins1_alu_opcode;
    assign ms_ins1_ins_type = ins1_alu_type;
    assign ms_ins1_imm_o = ins1_alu_imm;
    assign ms_ins1_immediate_o = ins1_imm;
    assign ms_ins1_dest_o = ins1_dest==0 ? 0 : w1_phys_reg;
    assign ms_ins1_hint_o = ins1_hint;
    assign ms_ins1_valid = !ins1_dnagn&!ins1_port&cyc_valid&!flush_i&!busy&!ins1_mov_elim&ins1_valid;
    assign ms_pack_id = rcu_pack[3:0];
    assign ms_rn_pc_o = insbundle_pc;
    assign ms_rn_bm_pred_o = btb_bm_pred;
    assign ms_rn_btype_o = btb_btype;
    assign ms_rn_btb_vld_o = btb_vld;
    assign ms_rn_btb_target_o = btb_target;
    assign ms_rn_btb_way_o = btb_way;
    assign ms_rn_btb_idx_o = btb_idx;
    assign ms_rn_btb_pack = rcu_pack[3:0];
    assign ms_rn_btb_wen = cyc_valid&!busy&!flush_i;
    assign ms_p0_data_o = {p0_phys_reg, p1_phys_reg, {rcu_pack, 1'b0}};
    assign ms_p0_sc_o = (|ins0_alu_type[2:1])|(ins0_alu_type[4])|(!(|ins0_alu_type));
    assign ms_p0_mc_o = (|ins0_alu_type[6:5]);
    assign ms_p0_vld_o = !ins0_port&!ins0_excp_valid&cyc_valid&!busy&!flush_i&!(ins0_mov_elim);
    assign ms_p0_rs1_vld_o = ins0_reg_props[1];
    assign ms_p0_rs2_vld_o = ins0_reg_props[0];
    assign ms_p0_rs1_rdy = r0_i;
    assign ms_p0_rs2_rdy = r1_i;
    assign ms_p1_data_o = {p2_phys_reg, p3_phys_reg, {rcu_pack,1'b1}};
    assign ms_p1_sc_o = (|ins1_alu_type[2:1]|(ins1_alu_type[4])|(!(|ins1_alu_type)));
    assign ms_p1_mc_o = |ins1_alu_type[6:5];
    assign ms_p1_vld_o = !ins1_port&!ins1_excp_valid&ins1_valid&cyc_valid&!flush_i&!busy&!(ins1_mov_elim);
    assign ms_p1_rs1_vld_o = ins1_reg_props[1];
    assign ms_p1_rs2_vld_o = ins1_reg_props[0];
    assign ms_p1_rs1_rdy = r2_i;
    assign ms_p1_rs2_rdy = r3_i;
    assign rcu_packet_pc=insbundle_pc;
    assign rcu_ins0_is_mov_elim=ins0_mov_elim;
    assign rcu_ins0_register_allocated=(ins0_reg_props[2]&!ins0_mov_elim)&!ins0_excp_valid&!(ins0_dest==0);
    assign rcu_ins0_arch_reg=ins0_dest;
    assign rcu_ins0_old_preg=p4_phys_reg;
    assign rcu_ins0_new_preg=w0_phys_reg;
    assign rcu_ins0_excp_code=ins0_excp_code;
    assign rcu_ins0_excp_valid=ins0_excp_valid;
    assign rcu_ins0_special=ins0_special;
    assign rcu_ins0_is_store=ins0_port&!ins0_dnagn&ins0_ios_type[3]&!ins0_excp_valid;
    assign rcu_ins1_is_mov_elim=ins1_mov_elim;
    assign rcu_ins1_register_allocated=(ins1_reg_props[2]&!ins1_mov_elim)&!ins1_excp_valid&!(ins1_dest==0)&&ins1_valid;
    assign rcu_ins1_arch_reg=ins1_dest;
    assign rcu_ins1_old_preg=(rcu_ins0_arch_reg==rcu_ins1_arch_reg)&&(rcu_ins0_is_mov_elim|rcu_ins0_register_allocated) ? rcu_ins0_new_preg : p5_phys_reg;
    assign rcu_ins1_new_preg=w1_phys_reg;
    assign rcu_ins1_excp_code=ins1_excp_code;
    assign rcu_ins1_excp_valid=ins1_excp_valid;
    assign rcu_ins1_special= ins1_special;
    assign rcu_ins1_is_store= ins1_port&!ins1_dnagn&ins1_ios_type[3]&!ins1_excp_valid;
    assign rcu_ins1_valid= ins1_valid;
    assign rcu_push_packet= cyc_valid&!busy&!flush_i;
    assign memSys_renamer_pkt_vld_o= cyc_valid&!busy&!flush_i&((ins1_port&!ins1_dnagn&!ins1_excp_valid&ins1_valid)||(ins0_port&!ins0_dnagn&!ins0_excp_valid));
    assign memSys_pkt0_rs1_o=ins0_dnr ? {1'b0,ins0_rs1} : p0_phys_reg;
    assign memSys_pkt0_rs2_o=p1_phys_reg;
    assign memSys_pkt0_dest_i=ins0_dest==0 ? 0 : w0_phys_reg;
    assign memSys_pkt0_immediate_o=ins0_imm;
    assign memSys_pkt0_ios_type_o=ins0_ios_type;
    assign memSys_pkt0_ios_opcode_o=ins0_ios_opcode;
    assign memSys_pkt0_rob_o=rcu_pack;
    assign memSys_pkt0_vld_o=ins0_port&!ins0_dnagn;
    assign memSys_pkt1_rs1_o=ins1_dnr ? {1'b0,ins1_rs1} : p2_phys_reg;
    assign memSys_pkt1_rs2_o=p3_phys_reg;
    assign memSys_pkt1_dest_o=ins1_dest==0 ? 0 : w1_phys_reg;
    assign memSys_pkt1_immediate_o=ins1_imm;
    assign memSys_pkt1_ios_type_o=ins1_ios_type;
    assign memSys_pkt1_ios_opcode_o=ins1_ios_opcode;
    assign memSys_pkt1_vld_o=ins1_port&!ins1_dnagn&ins1_valid;
    assign r0_vec_indx_o = p0_phys_reg;
    assign r1_vec_indx_o = p1_phys_reg;    
    assign r2_vec_indx_o = p2_phys_reg;
    assign r3_vec_indx_o = p3_phys_reg;
    assign p0_vec_indx_o = w0_phys_reg;
    assign p0_busy_vld_o = w0_we&!ins0_mov_elim;
    assign p1_vec_indx_o = w1_phys_reg;
    assign p1_busy_vld_o = w1_we&!ins1_mov_elim;
    assign o_rd0 = !(memSys_full|(ms_p0_busy_i|ms_p1_busy_i)|rcu_busy|flush_i)&cyc_valid&ins0_reg_props[2]&!ins0_mov_elim&!ins0_excp_valid;
    assign o_rd1 = !(memSys_full|(ms_p0_busy_i|ms_p1_busy_i)|rcu_busy|flush_i)&cyc_valid&ins1_reg_props[2]&!ins1_mov_elim&ins1_valid&!ins1_excp_valid;
endmodule
