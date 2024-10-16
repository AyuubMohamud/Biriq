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
op == 3'b000: maxu
op == 3'b001: minu
op == 3'b010: slt
op == 3'b011: sltu
op == 3'b100: max
op == 3'b101: min
op == 3'b110: czero.eqz
op == 3'b111: czero.nez
*/
module branch (
    input   wire logic  [31:0]  a, //! rs1
    input   wire logic  [31:0]  b, //! rs2 or imm
    input   wire logic  [2:0]   op, //! operation to be performed

    output  wire logic  [31:0]  c //! result
);
    wire [31:0] operand_2 = &op[2:1] ? 32'd0 : b;
    wire eq;
    assign eq = a == operand_2;
    wire gt_30;
    assign gt_30 = a[30:0] > operand_2[30:0];
    logic mts;
    logic mtu;
    always_comb begin
        case ({a[31], operand_2[31], gt_30})
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
    assign mt = op[2] ? mts : mtu;
    wire [31:0] max;
    wire [31:0] min;
    assign max = mt ? a : operand_2;
    assign min = !mt ? a : operand_2;
    
    // eq = 1  &&  !op[0] = 0
    // eq = 1  &&  op[0]  = a
    // eq = 0 && !op[0] = a
    // eq = 0 && op[0] = 0
    assign c = {op[2:1]}==2'b11 ? op[0]^eq ? a : 0 : {op[1:0]} == 2'b00 ? max : {op[1:0]} == 2'b01 ? min : {op[1:0]} == 2'b10 ? {31'h0, {!(mts|eq)}} : {31'h0, {!(mtu|eq)}};
    
endmodule
