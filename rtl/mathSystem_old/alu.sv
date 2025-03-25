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
1-clk ALU
*/

module alu (
    input   wire logic                      cpu_clock_i,
    input   wire logic                      flush_i,

    input   wire logic [31:0]               a,
    input   wire logic [31:0]               b,
    input   wire logic [6:0]                opc,
    input   wire logic [4:0]                rob_id,
    input   wire logic [5:0]                dest,
    input   wire logic                      valid,

    output       logic [31:0]               result,
    output       logic [4:0]                rob_id_o,
    output       logic                      wb_valid_o,
    output       logic [5:0]                dest_o,
    output       logic                      valid_o
);

    wire [31:0] adder_result;
    wire [31:0] shifter_result;
    wire [31:0] gates_result;
    wire [31:0] branch_result;
    adder adder0 (a, b, opc[3:0], adder_result);
    shifter shifter0 (a, b, opc[4:0], shifter_result); 
    gates gates0 (a, b, opc[3:0], gates_result);
    branch branchUnit0 (a, b, opc[2:0], branch_result);
    always_ff @(posedge cpu_clock_i) begin
        result <= opc[6:5] == 2'b00 ? adder_result :
                  opc[6:5] == 2'b01 ? shifter_result :
                  opc[6:5] == 2'b10 ? branch_result : 
                  gates_result;
        wb_valid_o <= !flush_i && valid && (dest!=0);
        rob_id_o <= rob_id;
        dest_o <= dest;
        valid_o <= valid&!flush_i;
    end
endmodule
