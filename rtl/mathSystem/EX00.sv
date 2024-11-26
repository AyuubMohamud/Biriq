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
module EX00 #(parameter ENABLE_C_EXTENSION = 0,
localparam PC_BITS = ENABLE_C_EXTENSION==1 ? 31 : 30,
localparam IDX_BITS = ENABLE_C_EXTENSION==1 ? 2 : 1) (
    input   wire logic                              cpu_clock_i,
    input   wire logic                              flush_i,

    input   wire logic [17:0]                       data_i,
    input   wire logic                              valid_i,

    output  wire logic [5:0]                        rs1_o,
    output  wire logic [5:0]                        rs2_o,
    input   wire logic [31:0]                       rs1_data_i,
    input   wire logic [31:0]                       rs2_data_i,

    output  wire logic [4:0]                        rob_o,
    // instruction ram
    input   wire logic [6:0]                        opcode_i,
    input   wire logic [5:0]                        ins_type, // 0 = ALU, 1 = JAL, 2 = JALR, 3 = LUI, 4 - AUIPC
    input   wire logic                              imm_i,
    input   wire logic [31:0]                       immediate_i,
    input   wire logic [5:0]                        dest_i,
    input   wire logic [1:0]                        hint_i,
    /* verilator lint_off UNUSED */
    input   wire logic                              ins_2byte,
    input   wire logic                              ins_2byte_p,
    /* verilator lint_on UNUSED */
    input   wire logic [PC_BITS-1:0]                pc_i,
    // Branch info
    input   wire logic [1:0]                        bm_pred_i,
    input   wire logic [1:0]                        btype_i,
    input   wire logic                              btb_vld_i,
    input   wire logic [PC_BITS-1:0]                btb_target_i,
    input   wire logic                              btb_way_i,
    input   wire logic [IDX_BITS-1:0]               btb_idx_i,

    output       logic [31:0]                       bnch_operand_1,
    output       logic [31:0]                       bnch_operand_2,
    output       logic [31:0]                       bnch_offset,
    output       logic [PC_BITS-1:0]                bnch_pc,
    output       logic                              bnch_auipc,
    output       logic                              bnch_call,
    output       logic                              bnch_ret,
    output       logic                              bnch_jal,
    output       logic                              bnch_jalr,
    output       logic [2:0]                        bnch_bnch_cond,
    output       logic [5:0]                        bnch_rob_id_o,
    output       logic                              bnch_ins_sz_o,
    output       logic [5:0]                        bnch_dest_o, 
    output       logic [1:0]                        bnch_bm_pred_o,
    output       logic [1:0]                        bnch_btype_o,
    output       logic                              bnch_btb_vld_o,
    output       logic [PC_BITS-1:0]                bnch_btb_target_o,
    output       logic                              bnch_btb_way_o,
    output       logic                              bnch_valid_o,

    output       logic [31:0]                       alu_a,
    output       logic [31:0]                       alu_b,
    output       logic [6:0]                        alu_opc,
    output       logic [4:0]                        alu_rob_id,
    output       logic [5:0]                        alu_dest,
    output       logic                              alu_valid,

    output       logic [31:0]                       valu_a,
    output       logic [31:0]                       valu_b,
    output       logic [6:0]                        valu_opc,
    output       logic [4:0]                        valu_rob_id,
    output       logic [5:0]                        valu_dest,
    output       logic                              valu_valid,

    output       logic [5:0]                        wakeup_dest,
    output       logic                              wakeup_valid
);
    assign rob_o = data_i[4:0];
    assign rs1_o = data_i[11:6];
    assign rs2_o = data_i[17:12];
    initial wakeup_valid = 0; initial alu_valid = 0;
    wire [PC_BITS-1:0] pc;
    wire btb_vld_specific;
    wire ins_sz;
    generate if (ENABLE_C_EXTENSION) begin : _IALIGN2
        assign pc = {pc_i[30:2], data_i[0] ? ins_2byte_p ? pc_i[1:0]+2'b01 : pc_i[1:0]+2'b10 : pc_i[1:0]};
        assign btb_vld_specific = btb_vld_i&(btb_idx_i==(ins_2byte ? pc[1:0] : pc[1:0]==2'b00 ? 2'b01 : pc[1:0]==2'b01 ? 2'b10 : pc[1:0]==2'b10 ? 2'b11 : 2'b00));
        assign ins_sz = ins_2byte;
    end else begin : _IALIGN4
        assign pc = {pc_i[29:1], pc_i[0] ? 1'b1 : data_i[0]};
        assign btb_vld_specific = btb_vld_i&(btb_idx_i==(pc_i[0] ? 1'b1 : data_i[0]));
        assign ins_sz = 1'b0;
    end endgenerate

    always_ff @(posedge cpu_clock_i) begin
        if (valid_i&!flush_i) begin
            alu_a <= ins_type[3] ? 32'd0 : rs1_data_i;
            alu_b <= imm_i|ins_type[3] ? immediate_i :  rs2_data_i;
            alu_opc <= ins_type[3] ? 7'd0 : opcode_i;
            alu_rob_id <= data_i[4:0];
            alu_dest <= dest_i;
            alu_valid <= ins_type[0]|ins_type[3];
            valu_a <= rs1_data_i;
            valu_b <= rs2_data_i;
            valu_opc <= opcode_i;
            valu_rob_id <= data_i[4:0];
            valu_dest <= dest_i;
            valu_valid <= ins_type[5];
            bnch_operand_1 <= rs1_data_i; bnch_operand_2 <= rs2_data_i;
            bnch_offset <= immediate_i; 
            bnch_pc <= pc;
            bnch_auipc <= ins_type[4]; bnch_jal <= ins_type[1]; bnch_jalr <= ins_type[2];
            bnch_bnch_cond <= opcode_i[2:0]; bnch_rob_id_o <= data_i[5:0]; bnch_dest_o <= dest_i; bnch_bm_pred_o <= bm_pred_i;
            bnch_btype_o <= btype_i;
            bnch_btb_vld_o <= btb_vld_specific;
            bnch_btb_target_o <= btb_target_i;
            bnch_btb_way_o <= btb_way_i; // mask off appropriately
            wakeup_dest <= dest_i;
            bnch_valid_o <= ((|ins_type[2:1])||ins_type[4]||(!ins_type[0]&!ins_type[5]&!ins_type[3]));
            wakeup_valid <= (|ins_type);
            bnch_call <= hint_i[1];
            bnch_ret <= hint_i[0];
            bnch_ins_sz_o <= ins_sz;
        end else begin
            alu_valid <= 0; bnch_valid_o <= 0; valu_valid <= 0;
        end
    end

endmodule
