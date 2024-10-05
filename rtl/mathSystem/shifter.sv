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
//  | PARTICULAR PURPOSE. Please see the CERN-OHL-S v2 for applicable conditions.           |
//  |                                                                                       |
//  | Source location: https://github.com/AyuubMohamud/Biriq                                |
//  |                                                                                       |
//  | As per CERN-OHL-W v2 section 4, should You produce hardware based on this             |
//  | source, You must where practicable maintain the Source Location visible               |
//  | in the same manner as is done within this source.                                     |
//  |                                                                                       |
//  -----------------------------------------------------------------------------------------

/*
op == 5'b00000: sll
op == 5'b00001: slr
op == 5'b00010: rol
op == 5'b00011: ror
op == 5'b00101: sra
op == 5'b01000: bclr
op == 5'b01011: bext
op == 5'b11000: binv
op == 5'b11010: bset
Everything else is undefined
*/

module shifter (
    input   wire logic  [31:0]  a, //! rs1
    /* verilator lint_off UNUSED*/
    input   wire logic  [31:0]  b, //! rs2 or imm
    /* verilator lint_on UNUSED*/
    input   wire logic  [4:0]   op, //! operation to be performed

    output  wire logic  [31:0]  c //! result
);
    
    // shifter, default is shift left, to shift right it is op[0] = 1
    wire [31:0] shift_res;
    wire [31:0] operand_1;
    wire [4:0] shamt;
    assign operand_1 = op[3]&!op[0] ? 32'b1 : a;
    assign shamt = b[4:0];
    wire [31:0] shift_operand1;
    
    for (genvar i = 0; i < 32; i++) begin
        assign shift_operand1[i] = !op[0] ? operand_1[31-i] : operand_1[i];
    end

    wire [31:0] shift_stage1;
    assign shift_stage1[31] = op[1] & !op[3] ? shift_operand1[0] : (!op[3] & op[2]) ? a[31] : 1'b0;
    assign shift_stage1[30:0] = shift_operand1[31:1]; 

    wire [31:0] shift_res_stage1;
    assign shift_res_stage1 = shamt[0] ? shift_stage1 : shift_operand1;

    wire [31:0] shift_stage2;
    assign shift_stage2[31:30] = op[1] & !op[3] ? shift_res_stage1[1:0] :  (!op[3] & op[2]) ? {{2{a[31]}}} : 2'b00;
    assign shift_stage2[29:0] = shift_res_stage1[31:2]; 

    wire [31:0] shift_res_stage2;
    assign shift_res_stage2 = shamt[1] ? shift_stage2 : shift_res_stage1;

    wire [31:0] shift_stage3;
    assign shift_stage3[31:28] = op[1] & !op[3] ? shift_res_stage2[3:0] : (!op[3] & op[2]) ? {{4{a[31]}}} : 4'b00;
    assign shift_stage3[27:0] = shift_res_stage2[31:4]; 

    wire [31:0] shift_res_stage3;
    assign shift_res_stage3 = shamt[2] ? shift_stage3 : shift_res_stage2;

    wire [31:0] shift_stage4;
    assign shift_stage4[31:24] = op[1] & !op[3] ? shift_res_stage3[7:0] : (!op[3] & op[2]) ? {{8{a[31]}}} : 8'b00;
    assign shift_stage4[23:0] = shift_res_stage3[31:8]; 

    wire [31:0] shift_res_stage4;
    assign shift_res_stage4 = shamt[3] ? shift_stage4 : shift_res_stage3;

    wire [31:0] shift_stage5;
    assign shift_stage5[31:16] = op[1] & !op[3] ? shift_res_stage4[15:0] : (!op[3] & op[2]) ? {{16{a[31]}}} : 16'b00;
    assign shift_stage5[15:0] = shift_res_stage4[31:16]; 

    wire [31:0] shift_res_stage5;
    assign shift_res_stage5 = shamt[4] ? shift_stage5 : shift_res_stage4;

    for (genvar i = 0; i < 32; i++) begin
        assign shift_res[i] = !op[0] ? shift_res_stage5[31-i] : shift_res_stage5[i];
    end


    // postgate
    logic [31:0] postgate_res;
    always_comb begin
        case ({op[4],op[1]})
            2'b00: postgate_res = a & ~shift_res;
            2'b01: postgate_res = shift_res & 1;
            2'b10: postgate_res = a ^ shift_res;
            2'b11: postgate_res = a | shift_res;
        endcase
    end

    assign c = op[3] ? postgate_res : shift_res;
    
endmodule
/* verilator lint_on SELRANGE*/
