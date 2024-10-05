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
module op_imm_dec (
    input   wire logic [6:0]    func7,
    input   wire logic [2:0]    func3,
    input   wire logic [4:0]    rs2_field,

    output  wire logic [6:0]    uop,
    output  wire logic          valid
);
    // 21 LUTs in vivado, synthesis defaults
    localparam RV_ADD = 7'b0000000;
    localparam RV_SLL = 7'b0100000;
    localparam RV_SLR = 7'b0100001;
    localparam RV_SRA = 7'b0100101;
    localparam RV_BCLR = 7'b0101000;
    localparam RV_BEXT = 7'b0101011;
    localparam RV_BINV = 7'b0111000;
    localparam RV_BSET = 7'b0111010;
    localparam RV_SLT = 7'b1000010;
    localparam RV_SLTU = 7'b1000011;
    localparam RV_AND = 7'b1100000;
    localparam RV_ORR = 7'b1100001;
    localparam RV_XOR = 7'b1100010;
    localparam RV_CLZ = 7'b1101100;
    localparam RV_CTZ = 7'b1101000;
    localparam RV_ORC_B = 7'b1100011;
    localparam RV_REV8 = 7'b1101010;
    localparam RV_CPOP = 7'b1101011;
    localparam RV_SEXT_B = 7'b0001000;
    localparam RV_SEXT_H = 7'b0001001;
    localparam RV_ROR = 7'b0100011;
    // case 000
    wire [6:0] equiv_000_instruc_t = RV_ADD;
    // case 001
    wire isBx = (!func7[6]&(func7[5]|func7[4])&!func7[3]&func7[2]&!func7[1]&!func7[0]);
    // this essentially says i want 0xx0100 and not 0000100 which is illegal
    wire isRest = {func7,rs2_field[4:3]}==9'b011000000 && !(&rs2_field[2:1]|&rs2_field[1:0]); 
    wire isSLLI = func7==0;
    wire [6:0] equiv_instruc_0 = rs2_field[2:0] == 3'b000 ? RV_CLZ : // clz
                                 rs2_field[2:0] == 3'b010 ? RV_CPOP : // cpop (complex)
                                 rs2_field[2:0] == 3'b001 ? RV_CTZ : // ctz
                                 rs2_field[2:0] == 3'b100 ? RV_SEXT_B : // sext.b
                                 RV_SEXT_H; // sext.h
    wire [6:0] equiv_instruc_1 = func7[5:4] == 2'b10 ? RV_BCLR : // bclr
                                 func7[5:4] == 2'b11 ? RV_BINV : // binv
                                 RV_BSET;// bset
    wire [6:0] equiv_001_instruc_t = isBx ? equiv_instruc_1 : isSLLI ? RV_SLL : equiv_instruc_0;

    // case 010
    wire [6:0] equiv_010_instruc_t = RV_SLT; // slti
    // case 011
    wire [6:0] equiv_011_instruc_t = RV_SLTU; // sltiu
    // case 100
    wire [6:0] equiv_100_instruc_t = RV_XOR; // xor
    // case 101
    wire isORCB = {func7, rs2_field}==12'b001010000111;
    wire isREV8 = {func7, rs2_field}==12'b011010011000;
    wire isOther = !func7[6]&!func7[3]&!func7[1]&!func7[0]&((!func7[2]&!func7[4])||(!func7[4]&func7[5])||(func7[5]&!func7[2]));
    wire [6:0] equiv_101_instruc_0 = {func7[5:4], func7[2]} == 3'b000 ? RV_SLR : // srli
                               {func7[5:4], func7[2]} == 3'b100 ? RV_SRA : // srai
                               {func7[5:4], func7[2]} == 3'b110 ? RV_ROR : // rori
                               RV_BEXT; // bext
    wire [6:0] equiv_101_instruc_t = isORCB ? RV_ORC_B : isREV8 ? RV_REV8 : equiv_101_instruc_0;

    // case 110
    wire [6:0] equiv_110_instruc_t = RV_ORR; // ori
    // case 111
    wire [6:0] equiv_111_instruc_t = RV_AND; // andi

    assign valid =   func3 == 3'b001 ? (isBx|isRest|isSLLI) :
                     func3 == 3'b101 ? (isORCB|isREV8|isOther) : 1;
    
    assign uop = func3 == 3'b000 ? equiv_000_instruc_t :
                           func3 == 3'b001 ? equiv_001_instruc_t :
                           func3 == 3'b010 ? equiv_010_instruc_t :
                           func3 == 3'b011 ? equiv_011_instruc_t :
                           func3 == 3'b100 ? equiv_100_instruc_t :
                           func3 == 3'b101 ? equiv_101_instruc_t :
                           func3 == 3'b110 ? equiv_110_instruc_t : 
                           equiv_111_instruc_t;


    
endmodule
