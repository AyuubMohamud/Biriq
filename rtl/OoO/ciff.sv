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
module ciff (
    input   wire logic                  cpu_clk_i,
    input   wire logic                  flush_i,

    input   wire logic [4:0]            alu0_rob_slot_i,
    input   wire logic                  alu0_rob_complete_i,
    input   wire logic                  alu0_call_i,
    input   wire logic                  alu0_ret_i,

    input   wire logic [4:0]            alu1_rob_slot_i,
    input   wire logic                  alu1_rob_complete_i,

    input   wire logic [4:0]            agu0_rob_slot_i,
    input   wire logic                  agu0_rob_complete_i,

    input   wire logic [4:0]            ldq_rob_slot_i,
    input   wire logic                  ldq_rob_complete_i,

    input   wire logic [4:0]            rob0_status,
    input   wire logic                  commit0,
    output  wire logic                  rob0_status_o,
    output  wire logic                  rob0_call_o,
    output  wire logic                  rob0_ret_o,

    input   wire logic [4:0]            rob1_status,
    input   wire logic                  commit1,
    output  wire logic                  rob1_status_o,
    output  wire logic                  rob1_call_o,
    output  wire logic                  rob1_ret_o
);
    reg [31:0] rob_status_bits = 0;
    reg [31:0] call = 0;
    reg [31:0] ret = 0;
    for (genvar i = 0; i < 32; i = i + 2) begin : rob0_x
        always_ff @(posedge cpu_clk_i) begin
            rob_status_bits[i] <= flush_i ? 1'b0 : (rob0_status==i)&&commit0  ? 1'b0 : (alu0_rob_slot_i==i)&&alu0_rob_complete_i ? 1'b1 : 
            (alu1_rob_slot_i==i)&&alu1_rob_complete_i ? 1'b1 : (agu0_rob_slot_i==i)&&agu0_rob_complete_i ? 1'b1 : (ldq_rob_slot_i==i)&&ldq_rob_complete_i ? 1'b1 : rob_status_bits[i];
            call[i] <= flush_i ? 1'b0 : (rob0_status==i)&&commit0  ? 1'b0 : (alu0_rob_slot_i==i)&&alu0_rob_complete_i&&alu0_call_i ? 1'b1 : call[i];
            ret[i] <= flush_i ? 1'b0 : (rob0_status==i)&&commit0  ? 1'b0 : (alu0_rob_slot_i==i)&&alu0_rob_complete_i&&alu0_ret_i ? 1'b1 : ret[i];
        end
    end
    for (genvar i = 1; i < 32; i = i + 2) begin : rob0_y
        always_ff @(posedge cpu_clk_i) begin
            rob_status_bits[i] <= flush_i ? 1'b0 : (rob1_status==i)&&commit1  ? 1'b0 : (alu0_rob_slot_i==i)&&alu0_rob_complete_i ? 1'b1 : 
            (alu1_rob_slot_i==i)&&alu1_rob_complete_i ? 1'b1 : (agu0_rob_slot_i==i)&&agu0_rob_complete_i ? 1'b1 : (ldq_rob_slot_i==i)&&ldq_rob_complete_i ? 1'b1 : rob_status_bits[i];
            call[i] <= flush_i ? 1'b0 : (rob1_status==i)&&commit1  ? 1'b0 : (alu0_rob_slot_i==i)&&alu0_rob_complete_i&&alu0_call_i ? 1'b1 : call[i];
            ret[i] <= flush_i ? 1'b0 : (rob1_status==i)&&commit1  ? 1'b0 : (alu0_rob_slot_i==i)&&alu0_rob_complete_i&&alu0_ret_i ? 1'b1 : ret[i];
        end
    end
    assign rob0_status_o = rob_status_bits[rob0_status];
    assign rob0_call_o = call[rob0_status];
    assign rob0_ret_o = ret[rob0_status];
    assign rob1_status_o = rob_status_bits[rob1_status];
    assign rob1_call_o = call[rob1_status];
    assign rob1_ret_o = ret[rob1_status];
endmodule
