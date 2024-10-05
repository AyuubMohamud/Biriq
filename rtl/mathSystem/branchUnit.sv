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
module branchUnit (
    input   wire logic                      cpu_clock_i,
    input   wire logic                      flush_i,
    // base instruction information
    input   wire logic [31:0]               operand_1,
    input   wire logic [31:0]               operand_2,
    input   wire logic [31:0]               offset,
    input   wire logic [29:0]               pc,
    input   wire logic                      auipc,
    input   wire logic                      call,
    input   wire logic                      ret,
    input   wire logic                      jal,
    input   wire logic                      jalr,
    input   wire logic [2:0]                bnch_cond,
    input   wire logic [5:0]                rob_id_i,
    input   wire logic [5:0]                dest_i,
    // btb info
    input   wire logic  [1:0]               bm_pred_i,
    input   wire logic  [1:0]               btype_i,
    input   wire logic                      btb_vld_i,
    input   wire logic  [29:0]              btb_target_i,
    input   wire logic                      btb_way_i,
    input   wire logic                      valid_i,

    output  logic  [31:0]                   result_o,
    output  logic                           wb_valid_o,
    output  logic  [5:0]                    wb_dest_o,
    output  logic                           res_valid_o,
    output  logic [5:0]                     rob_o,    
    output  logic                           rcu_excp_o,
    output  logic  [29:0]                   c1_btb_vpc_o, //! SIP PC
    output  logic  [31:0]                   c1_btb_target_o, //! SIP Target **if** taken
    output  logic  [1:0]                    c1_cntr_pred_o, //! Bimodal counter prediction,
    output  logic                           c1_bnch_tkn_o, //! Branch taken this cycle
    output  logic  [1:0]                    c1_bnch_type_o,
    output  logic                           c1_bnch_present_o,
    output  logic                           c1_btb_way_o,
    output  logic                           c1_btb_bm_mod_o,
    output  logic                           c1_call_affirm_o,
    output  logic                           c1_ret_affirm_o
);

    wire eq;
    assign eq = operand_1 == operand_2;
    wire gt_30;
    assign gt_30 = operand_1[30:0] > operand_2[30:0];
    logic mts;
    logic mtu;
    always_comb begin
        case ({operand_1[31], operand_2[31], gt_30})
            3'b000: begin
                mts = 0; mtu = 0;
            end
            3'b001: begin
                mts = 1; mtu = 1;
            end
            3'b010: begin
                mts = 1; mtu = 0;
            end
            3'b011: begin
                mts = 1; mtu = 0;
            end
            3'b100: begin
                mts = 0; mtu = 1;
            end
            3'b101: begin
                mts = 0; mtu = 1;
            end
            3'b110: begin
                mts = 0; mtu = 0;
            end
            3'b111: begin
                mts = 1; mtu = 1;
            end
        endcase
    end

    wire mt;
    assign mt = !bnch_cond[1] ? mts : mtu;
    wire lt;
    assign lt = !(mt | eq);

    wire brnch_res;
    assign brnch_res = {bnch_cond[2], bnch_cond[0]} == 2'b00 ? eq :
                       {bnch_cond[2], bnch_cond[0]} == 2'b01 ? !eq : 
                       {bnch_cond[2], bnch_cond[0]} == 2'b10 ? lt :
                       mt|eq; 
    wire [31:0] excp_addr;
    wire [31:0] first_operand = jalr ? operand_1 : {pc,2'b00};
    wire [31:0] second_operand = (jal|jalr|brnch_res)&&!(auipc) ? offset : 32'd4;

    assign excp_addr = first_operand+second_operand;
    wire wrongful_nbranch = !btb_vld_i&&!(auipc);
    wire wrongful_target = {btb_target_i,2'b00}!=excp_addr && btb_vld_i;
    //wire [1:0] branch_type = call ? 2'b01 : ret ? 2'b11 : jal|jalr ? 2'b10 : 2'b00;
    wire [1:0] branch_type = call ? 2'b01 : ret ? 2'b11 : jal|jalr ? 2'b10 : 2'b00;
    wire wrongful_type = branch_type!=btype_i && btb_vld_i;
    wire wrongful_bm = (brnch_res^bm_pred_i[1]) && btb_vld_i && branch_type==2'b00;    
    initial rcu_excp_o = 0; initial wb_valid_o = 0; initial res_valid_o = 0;                
    always_ff @(posedge cpu_clock_i) begin
        wb_valid_o <= !flush_i&valid_i&(auipc|jal|jalr)&!(dest_i==0);
        res_valid_o <= !flush_i&valid_i;
        result_o <= auipc ? offset+{pc,2'b00} : {pc+30'h1,2'b00};
        wb_dest_o <= dest_i;
        rob_o <= rob_id_i;
        if (((wrongful_nbranch&(brnch_res|(branch_type[1:0]!=2'b00)))|wrongful_target|wrongful_type|wrongful_bm)&& !flush_i && valid_i) begin
            rcu_excp_o <= 1;
            c1_btb_bm_mod_o <= 0;
            c1_call_affirm_o <= 0;
            c1_ret_affirm_o <= 0;
        end
        else if (!(wrongful_nbranch|wrongful_target|wrongful_type|wrongful_bm) && btb_vld_i && !flush_i && valid_i) begin
            c1_btb_bm_mod_o <= !(call|ret);
            c1_call_affirm_o <= call;
            c1_ret_affirm_o <= ret;
            rcu_excp_o <= 0;
        end
        else begin
            c1_btb_bm_mod_o <= 0;
            c1_call_affirm_o <= 0;
            c1_ret_affirm_o <= 0;
            rcu_excp_o <= 0;
        end
        c1_btb_way_o <= btb_way_i;
        c1_btb_vpc_o <= pc;
        c1_btb_target_o <= excp_addr;
        c1_cntr_pred_o <= bm_pred_i;
        c1_bnch_tkn_o <= (brnch_res|(branch_type[1:0]!=2'b00));
        c1_bnch_type_o <= branch_type;
        c1_bnch_present_o <= (brnch_res|(branch_type[1:0]!=2'b00));
    end

endmodule
