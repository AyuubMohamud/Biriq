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
//  | PARTICULAR PURPOSE. Please see the CERN-OHL-S v2 for applicable conditions.           |
//  |                                                                                       |
//  | Source location: https://github.com/AyuubMohamud/Biriq                                |
//  |                                                                                       |
//  | As per CERN-OHL-W v2 section 4, should You produce hardware based on this             |
//  | source, You must where practicable maintain the Source Location visible               |
//  | in the same manner as is done within this source.                                     |
//  |                                                                                       |
//  -----------------------------------------------------------------------------------------
module EX02 (
    input   wire logic                              flush_i,

    input   wire logic [31:0]                       alu_result,
    input   wire logic [4:0]                        alu_rob_id_i,
    input   wire logic                              alu_wb_valid_i,
    input   wire logic [5:0]                        alu_dest_i,
    input   wire logic                              alu_valid_i,

    input   wire logic [31:0]                       valu_result,
    input   wire logic [4:0]                        valu_rob_id_i,
    input   wire logic                              valu_wb_valid_i,
    input   wire logic [5:0]                        valu_dest_i,
    input   wire logic                              valu_valid_i,

    input   wire logic  [31:0]                      brnch_result_i,
    input   wire logic                              brnch_wb_valid_i,
    input   wire logic  [5:0]                       brnch_wb_dest_i,
    input   wire logic                              brnch_res_valid_i,
    input   wire logic [5:0]                        brnch_rob_i,
    input   wire logic                              brnch_rcu_excp_i,
    input   wire logic  [29:0]                      c1_btb_vpc_i,
    input   wire logic  [31:0]                      c1_btb_target_i,
    input   wire logic  [1:0]                       c1_cntr_pred_i,
    input   wire logic                              c1_bnch_tkn_i,
    input   wire logic  [1:0]                       c1_bnch_type_i,
    input   wire logic                              c1_bnch_present_i,
    input   wire logic                              c1_btb_way_i,
    input   wire logic                              c1_btb_bm_mod_i,
    input   wire logic                              c1_call_affirm_i,
    input   wire logic                              c1_ret_affirm_i,
    // update bimodal counters here OR tell control unit to correct exec path

    output  wire logic [31:0]                       p0_we_data,
    output  wire logic [5:0]                        p0_we_dest,
    output  wire logic                              p0_wen,

    output  wire logic [5:0]                        excp_rob,
    output  wire logic [4:0]                        excp_code,
    output  wire logic                              excp_valid,
    output  wire logic  [29:0]                      c1_btb_vpc_o,
    output  wire logic  [29:0]                      c1_btb_target_o,
    output  wire logic  [1:0]                       c1_cntr_pred_o,
    output  wire logic                              c1_bnch_tkn_o,
    output  wire logic  [1:0]                       c1_bnch_type_o,
    output  wire logic                              c1_bnch_present_o,
    output  wire logic                              c1_call_affirm_o,
    output  wire logic                              c1_ret_affirm_o,
    // to the btb
    output  wire logic                              wb_btb_way_o,
    output  wire logic                              wb_btb_bm_mod_o,

    output  wire logic [4:0]                        ins_completed,
    output  wire logic                              ins_cmp_v
);
    
    assign p0_we_data = valu_wb_valid_i ? valu_result : brnch_wb_valid_i ? brnch_result_i : alu_result;
    assign p0_we_dest = valu_wb_valid_i ? valu_dest_i : brnch_wb_valid_i ? brnch_wb_dest_i : alu_dest_i;
    assign p0_wen = (brnch_wb_valid_i|alu_wb_valid_i|valu_wb_valid_i)&!flush_i;
    assign excp_rob = brnch_rob_i; assign excp_code = |c1_btb_target_i[1:0] ? 5'b00000 : 5'b10000; assign excp_valid = brnch_rcu_excp_i;
    assign c1_btb_vpc_o = c1_btb_vpc_i; assign c1_btb_target_o = c1_btb_target_i[31:2]; assign c1_cntr_pred_o = c1_cntr_pred_i; assign c1_bnch_tkn_o = c1_bnch_tkn_i;
    assign c1_bnch_type_o = c1_bnch_type_i; assign c1_bnch_present_o = c1_bnch_present_i; assign wb_btb_way_o = c1_btb_way_i; assign wb_btb_bm_mod_o = c1_btb_bm_mod_i;
    assign ins_completed = valu_valid_i ? valu_rob_id_i : brnch_res_valid_i ? brnch_rob_i[4:0] : alu_rob_id_i;
    assign ins_cmp_v = valu_valid_i|brnch_res_valid_i|alu_valid_i;
    assign c1_call_affirm_o = c1_call_affirm_i&brnch_res_valid_i; assign c1_ret_affirm_o = c1_ret_affirm_i&brnch_res_valid_i;
endmodule
