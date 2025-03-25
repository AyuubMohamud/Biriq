/* verilator lint_off SELRANGE*/
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

/*
op == 3'b000: sll
op == 3'b001: slr
op == 3'b010: rol
op == 3'b011: ror
op == 3'b101: sra
Everything else is undefined
*/

module ivshifter (
    input   wire logic  [31:0]  a, //! rs1
    input   wire logic  [31:0]  b, //! rs2 or imm
    input   wire logic          size,
    input   wire logic  [2:0]   op, //! operation to be performed

    output  wire logic  [31:0]  c //! result
);
    
    // shifter, default is shift left, to shift right it is op[0] = 1
    wire [31:0] shift_res;
    wire [31:0] operand_1;
    assign operand_1 = a;
    wire [31:0] shift_operand1;
    wire [31:0] shamt_extract;
    for (genvar i = 0; i < 32; i++) begin : brev0
        assign shift_operand1[i] = !op[0] ? operand_1[31-i] : operand_1[i];
    end
    assign shamt_extract = !op[0] ? {b[7:0], b[15:8], b[23:16], b[31:24]} : b;

    wire [31:0] shift_stage1;
    assign shift_stage1[31] = op[1] ? size==1'b1 ? shift_operand1[16] : shift_operand1[24] : (op[2]) ? a[31]: 1'b0;
    assign shift_stage1[30:24] = shift_operand1[31:25];
    assign shift_stage1[23] =  op[1] ? size==1'b1 ? shift_operand1[24] : shift_operand1[16] : (op[2] & size==0) ? a[23]: (size==0) ? 1'b0 : shift_operand1[24];
    assign shift_stage1[22:16] = shift_operand1[23:17];
    assign shift_stage1[15] = op[1] ? size==1'b1 ? shift_operand1[0] : shift_operand1[8] : (op[2]) ? a[15]: 1'b0;
    assign shift_stage1[14:8] = shift_operand1[15:9];
    assign shift_stage1[7] = op[1] ? size==1'b1 ? shift_operand1[8] : shift_operand1[0] : (op[2] & size==0) ? a[8]: (size==0) ? 1'b0 : shift_operand1[8];
    assign shift_stage1[6:0] = shift_operand1[7:1];
    wire [31:0] shift_res_stage1;
    assign shift_res_stage1[7:0]   = shamt_extract[0] ? shift_stage1[7:0]   : shift_operand1[7:0]  ;
    assign shift_res_stage1[15:8]  = shamt_extract[8] ? shift_stage1[15:8]  : shift_operand1[15:8] ;
    assign shift_res_stage1[23:16] = shamt_extract[16] ? shift_stage1[23:16] : shift_operand1[23:16];
    assign shift_res_stage1[31:24] = shamt_extract[24] ? shift_stage1[31:24] : shift_operand1[31:24];
    wire [31:0] shift_stage2;
    assign shift_stage2[31:30] = op[1] ? size==1'b1 ? shift_res_stage1[17:16] : shift_res_stage1[25:24] :  (op[2])
     ? {{2{a[31]}}} : 2'b00;
    assign shift_stage2[29:24] = shift_res_stage1[31:26]; 
    assign shift_stage2[23:22] = op[1] ? size==1'b1 ? shift_res_stage1[25:24] : shift_res_stage1[17:16] : (op[2] & size==0)
    ? {{2{a[23]}}} : (size==0) ? 2'b00 : shift_res_stage1[25:24];
    assign shift_stage2[21:16] = shift_res_stage1[23:18];
    assign shift_stage2[15:14] =  op[1] ? size==1'b1 ? shift_res_stage1[1:0] : shift_res_stage1[9:8] : (op[2])
    ? {{2{a[15]}}} : 2'b00;
    assign shift_stage2[13:8] = shift_res_stage1[15:10];
    assign shift_stage2[7:6] = op[1] ? size==1'b1 ? shift_res_stage1[9:8] : shift_res_stage1[1:0] : (op[2] & size==0)
    ? {{2{a[7]}}} : (size==0) ? 2'b00 : shift_res_stage1[9:8];
    assign shift_stage2[5:0] = shift_res_stage1[7:2];
    wire [31:0] shift_res_stage2;
    assign shift_res_stage2[7:0]   = shamt_extract[1] ? shift_stage2[7:0]   : shift_res_stage1[7:0]  ;
    assign shift_res_stage2[15:8]  = shamt_extract[9] ? shift_stage2[15:8]  : shift_res_stage1[15:8] ;
    assign shift_res_stage2[23:16] = shamt_extract[17] ? shift_stage2[23:16] : shift_res_stage1[23:16];
    assign shift_res_stage2[31:24] = shamt_extract[25] ? shift_stage2[31:24] : shift_res_stage1[31:24];

    wire [31:0] shift_stage3;
    assign shift_stage3[31:28] = op[1] ? size==1'b1 ? shift_res_stage2[19:16] : shift_res_stage2[27:24] :
    (op[2]) ? {{4{a[31]}}} : 4'b00;
    assign shift_stage3[27:24] = shift_res_stage2[31:28];
    assign shift_stage3[23:20] =  op[1] ? size==1'b01 ? shift_res_stage2[27:24] : shift_res_stage2[19:16] : (op[2] & size==0)
    ? {{4{a[23]}}} : (size==0) ? 4'b00 : shift_res_stage2[27:24];
    assign shift_stage3[19:16] = shift_res_stage2[23:20];
    assign shift_stage3[15:12] = op[1] ? size==1'b1 ? shift_res_stage2[3:0] : shift_res_stage2[11:8] : (op[2])
    ? {{4{a[15]}}} : 4'b00;
    assign shift_stage3[11:8] = shift_res_stage2[15:12];
    assign shift_stage3[7:4] = op[1] ? size==1'b1 ? shift_res_stage2[11:8] : shift_res_stage2[3:0] : (op[2] & size==0)
    ? {{4{a[7]}}} : (size==0) ? 4'b00 : shift_res_stage2[11:8];
    assign shift_stage3[3:0] = shift_res_stage2[7:4];
    wire [31:0] shift_res_stage3;
    assign shift_res_stage3[7:0]   = shamt_extract[2] ?  shift_stage3[7:0]   : shift_res_stage2[7:0]  ;
    assign shift_res_stage3[15:8]  = shamt_extract[10] ? shift_stage3[15:8]  : shift_res_stage2[15:8] ;
    assign shift_res_stage3[23:16] = shamt_extract[18] ? shift_stage3[23:16] : shift_res_stage2[23:16];
    assign shift_res_stage3[31:24] = shamt_extract[26] ? shift_stage3[31:24] : shift_res_stage2[31:24];

    wire [31:0] shift_stage4;
    assign shift_stage4[31:24] = op[1] ? size==1'b1 ? shift_res_stage3[7:0] : shift_res_stage3[23:16] : (op[2]) ? {{8{a[31]}}} : 8'b00;
    assign shift_stage4[23:16] = shift_res_stage3[31:24];
    assign shift_stage4[15:8] =  op[1] ? size==1'b1 ? shift_res_stage3[23:16] : shift_res_stage3[7:0] : (op[2] & size==1) ? {{8{a[31]}}} : shift_res_stage3[23:16];
    assign shift_stage4[7:0] = shift_res_stage3[15:8];
    wire [31:0] shift_res_stage4;
    assign shift_res_stage4[15:0] = shamt_extract[3] ? shift_stage4[15:0] : shift_res_stage3[15:0];
    assign shift_res_stage4[31:16]= shamt_extract[19] ? shift_stage4[31:16] : shift_res_stage3[31:16];

    for (genvar i = 0; i < 32; i++) begin : brev
        assign shift_res[i] = !op[0] ? shift_res_stage4[31-i] : shift_res_stage4[i];
    end
    assign c = shift_res;
endmodule
/* verilator lint_on SELRANGE*/
