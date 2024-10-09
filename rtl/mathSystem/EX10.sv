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
module EX10 (
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
    input   wire logic                              imm_i,
    input   wire logic [31:0]                       immediate_i,
    input   wire logic [5:0]                        dest_i,
    input   wire logic                              psx_i,
    input   wire logic                              lui_i,

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
    output       logic                              valu_valid
);
    assign rob_o = data_i[4:0];
    assign rs1_o = data_i[11:6];
    assign rs2_o = data_i[17:12];
    initial alu_valid = 0; initial valu_valid = 0;
    always_ff @(posedge cpu_clock_i) begin
        if (valid_i&!flush_i) begin
            alu_a <= lui_i ? 32'd0 : rs1_data_i;
            alu_b <= imm_i|lui_i ? immediate_i :  rs2_data_i;
            alu_opc <= lui_i ? 7'd0 : opcode_i;
            alu_rob_id <= data_i[4:0];
            alu_dest <= dest_i;
            alu_valid <= !psx_i;
            valu_a <= rs1_data_i;
            valu_b <= rs2_data_i;
            valu_opc <= opcode_i;
            valu_rob_id <= data_i[4:0];
            valu_dest <= dest_i;
            valu_valid <= psx_i;
        end else begin
            alu_valid <= 0; valu_valid <= 0;
        end
    end

endmodule
