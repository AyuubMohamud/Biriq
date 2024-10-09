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

op == 4'b0000: add
op == 4'b0001: sh1add
op == 4'b0010: sh2add
op == 4'b0011: sh3add
op == 4'b0100: sub
op == 4'b0101:
op == 4'b1000: sext.b
op == 4'b1001: sext.h
op == 4'b1010: zext.h
op == 4'b1011: Undefined
*/
// Verified 22/06/2023
module adder
(
    input   wire logic  [31:0]  a, //! rs1
    input   wire logic  [31:0]  b, //! rs2 or imm

    input   wire logic  [3:0]   op, //! operation to be performed

    output  wire logic  [31:0]  c //! result
);
    wire [31:0] add_res; //! result of add
    wire [31:0] ext_res; //! result of extension

    assign ext_res = op[1:0] == 2'b00 ? {{24{a[7]}}, a[7:0]} : op[1:0] == 2'b01 ? {{16{a[15]}}, a[15:0]} : op[1:0] == 2'b10 ? {16'h0000, a[15:0]} : 32'h00000000;
    wire [31:0] sh_res; //! result of pre-shift
    assign sh_res = a << op[1:0];
    assign add_res = op[2] ? sh_res-b : sh_res+b;

    assign c = op[3] == 1'b0 ? add_res :ext_res; 
endmodule
