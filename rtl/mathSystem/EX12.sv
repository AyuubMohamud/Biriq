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
module EX12 (
    input   wire logic                              flush_i,

    input   wire logic [31:0]                       alu_result,
    input   wire logic [4:0]                        alu_rob_id_i,
    input   wire logic                              alu_wb_valid_i,
    input   wire logic [5:0]                        alu_dest_i,
    input   wire logic                              alu_valid_i,

    input   wire logic [31:0]                       valu_result,
    input   wire logic [4:0]                        valu_rob_id_i,
    input   wire logic                              valu_wb_valid_i,
    input   wire logic [5:0]                        valu_dest_i,
    input   wire logic                              valu_valid_i,
    // update bimodal counters here OR tell control unit to correct exec path

    output  wire logic [31:0]                       p0_we_data,
    output  wire logic [5:0]                        p0_we_dest,
    output  wire logic                              p0_wen,
    // rob
    output  wire logic [4:0]                        rob_id_o,
    output  wire logic                              rob_valid
);
    assign p0_we_data = valu_wb_valid_i ? valu_result : alu_result;
    assign p0_we_dest = valu_wb_valid_i ? valu_dest_i : alu_dest_i;
    assign p0_wen = (alu_wb_valid_i|valu_wb_valid_i)&!flush_i;
    assign rob_id_o = valu_valid_i ? valu_rob_id_i : alu_rob_id_i; assign rob_valid = (alu_valid_i|valu_valid_i)&!flush_i;
endmodule
