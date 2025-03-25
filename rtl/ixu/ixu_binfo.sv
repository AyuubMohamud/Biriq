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
module ixu_binfo (
    input  wire        core_clock_i,
    input  wire [29:0] rn_pc_i,
    input  wire [ 1:0] rn_bm_pred_i,
    input  wire [ 1:0] rn_btype_i,
    input  wire        rn_btb_vld_i,
    input  wire [29:0] rn_btb_target_i,
    input  wire        rn_btb_way_i,
    input  wire        rn_btb_idx_i,
    input  wire [ 3:0] rn_btb_pack,
    input  wire        rn_btb_wen,
    input  wire [ 3:0] pack_i,
    output wire [29:0] pc_o,
    output wire [ 1:0] bm_pred_o,
    output wire [ 1:0] btype_o,
    output wire        btb_vld_o,
    output wire [29:0] btb_target_o,
    output wire        btb_way_o,
    output wire        btb_idx_o
);
  reg [66:0] binfo_ram[0:15];

  always_ff @(posedge core_clock_i) begin
    if (rn_btb_wen) begin
      binfo_ram[rn_btb_pack] <= {
        rn_pc_i, rn_bm_pred_i, rn_btype_i, rn_btb_vld_i, rn_btb_target_i, rn_btb_way_i, rn_btb_idx_i
      };
    end
  end
  assign {pc_o,
    bm_pred_o,
    btype_o,
    btb_vld_o,
    btb_target_o,
    btb_way_o,
    btb_idx_o} = binfo_ram[pack_i];
endmodule
