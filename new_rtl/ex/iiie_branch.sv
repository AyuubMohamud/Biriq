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
module iiie_branch (
    input  wire        lt,
    input  wire        eq,
    // base instruction information
    input  wire [31:0] operand_1,
    input  wire [31:0] offset,
    input  wire [29:0] pc,
    input  wire        auipc,
    input  wire        call,
    input  wire        ret,
    input  wire        jal,
    input  wire        jalr,
    input  wire [ 2:0] bnch_cond,
    // btb info
    output wire        brnch_res,
    output wire [ 1:0] branch_type,
    output wire [31:0] excp_addr,
    output wire [31:0] result_o
);
  wire [31:0] first_operand;
  wire [31:0] second_operand;
  wire [31:0] second_first_opr;
  wire [31:0] second_second_opr;

  assign second_first_opr = {pc, 2'd0};
  assign second_second_opr = auipc ? offset : 32'd1;
  assign brnch_res  = {bnch_cond[2], bnch_cond[0]} == 2'b00 ? eq :   {bnch_cond[2], bnch_cond[0]} == 2'b01 ? !eq :    {bnch_cond[2], bnch_cond[0]} == 2'b10 ? lt :   ~lt;
  assign first_operand = jalr ? operand_1 : {pc, 2'b00};
  assign second_operand = (jal | jalr | brnch_res) && !(auipc) ? offset : 32'd4;
  assign excp_addr = first_operand + second_operand;
  assign branch_type = call ? 2'b01 : ret ? 2'b11 : jal | jalr ? 2'b10 : 2'b00;

  assign result_o = second_first_opr + second_second_opr;

endmodule
