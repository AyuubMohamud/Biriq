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
module frontend #(
    parameter [31:0] START_ADDR = 32'h0,
    parameter [31:0] BPU_ENTRIES = 32,
    parameter BPU_ENABLE_RAS = 1, 
    parameter BPU_RAS_ENTRIES = 32, 
    parameter ENABLE_PSX = 1, 
    parameter ENABLE_C_EXTENSION = 1, 
    parameter QUEUE_SZ = 8, 
    parameter QUEUE_OFF = 0, 
    parameter QUEUE_PASSTHROUGH = 1,
    localparam PC_BITS = ENABLE_C_EXTENSION==1 ? 31 : 30,
    localparam IDX_BITS = ENABLE_C_EXTENSION==1 ? 2 : 1
    )
(
    input   wire logic                          core_clock_i,
    input   wire logic                          core_reset_i,
    input   wire logic                          core_flush_i,
    input   wire logic [PC_BITS-1:0]            core_flush_pc,
    input   wire logic                          enable_branch_pred,
    input   wire logic                          enable_counter_overload,
    input   wire logic                          counter_overload,
    input   wire logic                          current_privlidge,
    input   wire logic                          tw,
    input   wire logic [1:0]                    cbie,
    input   wire logic                          cbcfe,
    input   wire logic                          cbze,
    // System control port
    input   wire logic                          cache_flush_i,
    // 00 - FLUSH, 01, Toggle ON/OFF, 1x undefined
    output  wire logic                          flush_resp_o,

    // TileLink Bus Master Uncached Heavyweight
    output       logic [2:0]                    icache_a_opcode,
    output       logic [2:0]                    icache_a_param,
    output       logic [3:0]                    icache_a_size,
    output       logic [31:0]                   icache_a_address,
    output       logic [3:0]                    icache_a_mask,
    output       logic [31:0]                   icache_a_data,
    output       logic                          icache_a_corrupt,
    output       logic                          icache_a_valid,
    input   wire logic                          icache_a_ready,

    input   wire logic [2:0]                    icache_d_opcode,
    input   wire logic [1:0]                    icache_d_param,
    input   wire logic [3:0]                    icache_d_size,
    input   wire logic                          icache_d_denied,
    input   wire logic [31:0]                   icache_d_data,
    input   wire logic                          icache_d_corrupt,
    input   wire logic                          icache_d_valid,
    output  wire logic                          icache_d_ready,
    // out to engine
    output       logic                  ins0_port_o,
    output       logic                  ins0_dnagn_o,
    output       logic [5:0]            ins0_alu_type_o,
    output       logic [6:0]            ins0_alu_opcode_o,
    output       logic                  ins0_alu_imm_o,
    output       logic [5:0]            ins0_ios_type_o,
    output       logic [2:0]            ins0_ios_opcode_o,
    output       logic [3:0]            ins0_special_o,
    output       logic [4:0]            ins0_rs1_o,
    output       logic [4:0]            ins0_rs2_o,
    output       logic [4:0]            ins0_dest_o,
    output       logic [31:0]           ins0_imm_o,
    output       logic [2:0]            ins0_reg_props_o,
    output       logic                  ins0_dnr_o,
    output       logic                  ins0_mov_elim_o,
    output       logic [1:0]            ins0_hint_o,
    output       logic                  ins0_2byte_o,
    output       logic                  ins0_excp_valid_o,
    output       logic [3:0]            ins0_excp_code_o,
    output       logic                  ins1_port_o,
    output       logic                  ins1_dnagn_o,
    output       logic [5:0]            ins1_alu_type_o,
    output       logic [6:0]            ins1_alu_opcode_o,
    output       logic                  ins1_alu_imm_o,
    output       logic [5:0]            ins1_ios_type_o,
    output       logic [2:0]            ins1_ios_opcode_o,
    output       logic [3:0]            ins1_special_o,
    output       logic [4:0]            ins1_rs1_o,
    output       logic [4:0]            ins1_rs2_o,
    output       logic [4:0]            ins1_dest_o,
    output       logic [31:0]           ins1_imm_o,
    output       logic [2:0]            ins1_reg_props_o,
    output       logic                  ins1_dnr_o,
    output       logic                  ins1_mov_elim_o,
    output       logic [1:0]            ins1_hint_o,
    output       logic                  ins1_2byte_o,
    output       logic                  ins1_excp_valid_o,
    output       logic [3:0]            ins1_excp_code_o,
    output       logic                  ins1_valid_o,
    output       logic [PC_BITS-1:0]    insbundle_pc_o,
    output       logic [1:0]            btb_btype_o,
    output       logic [1:0]            btb_bm_pred_o,
    output       logic [PC_BITS-1:0]    btb_target_o,
    output       logic                  btb_vld_o,
    output       logic                  btb_idx_o,
    output       logic                  btb_way_o,
    output       logic                  valid_o,
    input   wire logic                  rn_busy_i,

    input   wire logic [PC_BITS-1:0]    c1_btb_vpc_i,
    input   wire logic [PC_BITS-1:0]    c1_btb_target_i,
    input   wire logic [1:0]            c1_cntr_pred_i,
    input   wire logic                  c1_bnch_tkn_i,
    input   wire logic [1:0]            c1_bnch_type_i,
    input   wire logic                  c1_btb_mod_i,
    input   wire logic                  c1_btb_way_i,
    input   wire logic                  c1_btb_bm_i,
    input   wire logic                  c1_call_affirm_i,
    input   wire logic                  c1_ret_affirm_i,

    output  wire logic [24:0]           i_addr,
    input   wire logic                  i_kill
);
    wire logic               if2_busy_i;
    wire logic               if2_vld_o;
    wire logic [PC_BITS-1:0] if2_sip_vpc_o;
    wire logic [IDX_BITS-1:0]if2_btb_index;
    wire logic [1:0]         if2_btype_o;
    wire logic [1:0]         if2_bm_pred_o;
    wire logic [PC_BITS-1:0] if2_btb_target_o;
    wire logic               if2_btb_hit;
    wire logic               if2_btb_way;
    wire branch_correct; wire [PC_BITS-1:0] branch_correct_pc;
    pcgenA1 #(START_ADDR, BPU_ENTRIES, BPU_ENABLE_RAS, BPU_RAS_ENTRIES, ENABLE_C_EXTENSION) pcgenstage (core_clock_i, core_reset_i,core_flush_i|branch_correct, core_flush_i ? core_flush_pc : branch_correct_pc, enable_branch_pred,
    enable_counter_overload,
    counter_overload, if2_busy_i, branch_correct, branch_correct_pc,
    c1_btb_vpc_i, c1_btb_target_i, c1_cntr_pred_i, c1_bnch_tkn_i, c1_bnch_type_i, c1_btb_mod_i, c1_btb_way_i, c1_btb_bm_i,c1_call_affirm_i,
    c1_ret_affirm_i,
    if2_vld_o, if2_sip_vpc_o, if2_btype_o, if2_bm_pred_o, if2_btb_target_o, if2_btb_index, if2_btb_hit, if2_btb_way);

    wire logic                      pdc_hit_o;
    wire logic [63:0]               pdc_instruction_o;
    wire logic [PC_BITS-1:0]        pdc_sip_vpc_o;
    wire logic [3:0]                pdc_sip_excp_code_o;
    wire logic                      pdc_sip_excp_vld_o;
    wire logic [IDX_BITS-1:0]       pdc_btb_index_o;
    wire logic [1:0]                pdc_btb_btype_o;
    wire logic [1:0]                pdc_btb_bm_pred_o;
    wire logic [PC_BITS-1:0]        pdc_btb_target_o;
    wire logic                      pdc_btb_vld_o;
    wire logic                      pdc_btb_way_o;
    wire logic                      pdc_busy_i;
    icacheA1 #(ENABLE_C_EXTENSION) instructionCache (core_clock_i, core_flush_i|core_reset_i|branch_correct, if2_vld_o,if2_sip_vpc_o,if2_btb_index,if2_btype_o,if2_bm_pred_o,if2_btb_target_o,if2_btb_hit,if2_btb_way,
    if2_busy_i, pdc_hit_o, pdc_instruction_o, pdc_sip_vpc_o, pdc_sip_excp_code_o, pdc_sip_excp_vld_o, 
    pdc_btb_index_o, pdc_btb_btype_o, pdc_btb_bm_pred_o, pdc_btb_target_o, pdc_btb_vld_o, pdc_btb_way_o, pdc_busy_i, cache_flush_i,
    flush_resp_o,icache_a_opcode, icache_a_param, icache_a_size, icache_a_address, icache_a_mask, icache_a_data, icache_a_corrupt, icache_a_valid,
    icache_a_ready, icache_d_opcode, icache_d_param, icache_d_size, icache_d_denied, icache_d_data, icache_d_corrupt, icache_d_valid, icache_d_ready, i_addr, i_kill);

    wire logic                      mrq_hit_o;
    wire logic [63:0]               mrq_instruction_o;
    wire logic [PC_BITS-1:0]        mrq_sip_vpc_o;
    wire logic [3:0]                mrq_sip_excp_code_o;
    wire logic                      mrq_sip_excp_vld_o;
    wire logic [IDX_BITS-1:0]       mrq_btb_index_o;
    wire logic [1:0]                mrq_btb_btype_o;
    wire logic [1:0]                mrq_btb_bm_pred_o;
    wire logic [PC_BITS-1:0]        mrq_btb_target_o;
    wire logic                      mrq_btb_vld_o;
    wire logic                      mrq_btb_way_o;
    wire logic                      mrq_busy_i;
    mrq #(ENABLE_C_EXTENSION, QUEUE_SZ, QUEUE_OFF, QUEUE_PASSTHROUGH) memory_response_queue (
        core_clock_i, core_flush_i|core_reset_i|branch_correct, pdc_hit_o,pdc_instruction_o,pdc_sip_vpc_o,
        pdc_sip_excp_code_o,pdc_sip_excp_vld_o, 
        pdc_btb_index_o,pdc_btb_btype_o,pdc_btb_bm_pred_o,pdc_btb_target_o,pdc_btb_vld_o,pdc_btb_way_o,pdc_busy_i,
        mrq_hit_o,
        mrq_instruction_o,
        mrq_sip_vpc_o,
        mrq_sip_excp_code_o,
        mrq_sip_excp_vld_o,
        mrq_btb_index_o,
        mrq_btb_btype_o,
        mrq_btb_bm_pred_o,
        mrq_btb_target_o,
        mrq_btb_vld_o,
        mrq_btb_way_o,
        mrq_busy_i
    );
    wire                  dec_vld_o;
    wire [31:0]           dec0_instruction_o;
    wire                  dec0_instruction_is_2;
    wire [31:0]           dec1_instruction_o;
    wire                  dec1_instruction_is_2;
    wire                  dec1_instruction_valid_o;
    wire [PC_BITS-1:0]    dec_vpc_o;
    wire [3:0]            dec_excp_code_o;
    wire                  dec_excp_vld_o;
    wire [IDX_BITS-1:0]   dec_btb_index_o;
    wire [1:0]            dec_btb_btype_o;
    wire [1:0]            dec_btb_bm_pred_o;
    wire [PC_BITS-1:0]    dec_btb_target_o;
    wire                  dec_btb_vld_o;
    wire                  dec_btb_way_o;
    wire                  dec_busy_i;
    align #(ENABLE_C_EXTENSION) aligner (
        core_clock_i, core_flush_i|core_reset_i|branch_correct, mrq_hit_o,
        mrq_instruction_o,
        mrq_sip_vpc_o,
        mrq_sip_excp_code_o,
        mrq_sip_excp_vld_o,
        mrq_btb_index_o,
        mrq_btb_btype_o,
        mrq_btb_bm_pred_o,
        mrq_btb_target_o,
        mrq_btb_vld_o,
        mrq_btb_way_o,
        mrq_busy_i,
        dec_vld_o,
        dec0_instruction_o,
        dec0_instruction_is_2,
        dec1_instruction_o,
        dec1_instruction_is_2,
        dec1_instruction_valid_o,
        dec_vpc_o,
        dec_excp_code_o,
        dec_excp_vld_o,
        dec_btb_index_o,
        dec_btb_btype_o,
        dec_btb_bm_pred_o,
        dec_btb_target_o,
        dec_btb_vld_o,
        dec_btb_way_o,
        dec_busy_i
    );

    newDecode #(ENABLE_PSX, ENABLE_C_EXTENSION) decodeStage (core_clock_i, core_flush_i|core_reset_i, current_privlidge, tw,cbie,
    cbcfe,
    cbze, flush_resp_o, dec_vld_o,
    dec0_instruction_o,
    dec0_instruction_is_2,
    dec1_instruction_o,
    dec1_instruction_is_2,
    dec1_instruction_valid_o,
    dec_vpc_o,
    dec_excp_code_o,
    dec_excp_vld_o,
    dec_btb_index_o,
    dec_btb_btype_o,
    dec_btb_bm_pred_o,
    dec_btb_target_o,
    dec_btb_vld_o,
    dec_btb_way_o,
    dec_busy_i,
    ins0_port_o,
ins0_dnagn_o,
ins0_alu_type_o,
ins0_alu_opcode_o,
ins0_alu_imm_o,
ins0_ios_type_o,
ins0_ios_opcode_o,
ins0_special_o,
ins0_rs1_o,
ins0_rs2_o,
ins0_dest_o,
ins0_imm_o,
ins0_reg_props_o,
ins0_dnr_o,
ins0_mov_elim_o,
ins0_hint_o,
ins0_2byte_o,
ins0_excp_valid_o,
ins0_excp_code_o,
ins1_port_o,
ins1_dnagn_o,
ins1_alu_type_o,
ins1_alu_opcode_o,
ins1_alu_imm_o,
ins1_ios_type_o,
ins1_ios_opcode_o,
ins1_special_o,
ins1_rs1_o,
ins1_rs2_o,
ins1_dest_o,
ins1_imm_o,
ins1_reg_props_o,
ins1_dnr_o,
ins1_mov_elim_o,
ins1_hint_o,
ins1_2byte_o,
ins1_excp_valid_o,
ins1_excp_code_o,
ins1_valid_o,
insbundle_pc_o,
btb_btype_o,
btb_bm_pred_o,
btb_target_o,
btb_vld_o,
btb_idx_o,
btb_way_o,
valid_o,
rn_busy_i, branch_correct, branch_correct_pc
    );
endmodule
