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
module rst (
    input  wire        clk_i,
    input  wire        flush_i,
    input  wire  [5:0] p0_vec_indx_i,
    input  wire        p0_busy_vld_i,
    input  wire  [5:0] p1_vec_indx_i,
    input  wire        p1_busy_vld_i,
    input  wire  [5:0] p2_vec_indx_i,
    input  wire        p2_free_vld_i,
    input  wire  [5:0] p3_vec_indx_i,
    input  wire        p3_free_vld_i,
    input  wire  [5:0] p4_vec_indx_i,
    input  wire        p4_free_vld_i,
    input  wire  [5:0] p5_vec_indx_i,
    input  wire        p5_free_vld_i,
    input  wire  [5:0] r0_vec_indx_i,
    output logic       r0_o,
    input  wire  [5:0] r1_vec_indx_i,
    output logic       r1_o,
    input  wire  [5:0] r2_vec_indx_i,
    output logic       r2_o,
    input  wire  [5:0] r3_vec_indx_i,
    output logic       r3_o,
    input  wire  [5:0] r4_vec_indx_i,
    output logic       r4_o,
    input  wire  [5:0] r5_vec_indx_i,
    output logic       r5_o
);

  reg [63:0] rst_ff;
  initial rst_ff = '1;

  for (genvar k = 0; k < 64; k++) begin : g_
    always_ff @(posedge clk_i) begin
      rst_ff[k] <= flush_i ? 1'b1 : ((p0_busy_vld_i&(p0_vec_indx_i==k))||(p1_busy_vld_i&(p1_vec_indx_i==k))) ? 1'b0 :  ((p2_free_vld_i&(p2_vec_indx_i==k))||(p3_free_vld_i&(p3_vec_indx_i==k))||(p4_free_vld_i&(p4_vec_indx_i==k))||(p5_free_vld_i&(p5_vec_indx_i==k))) ? 1'b1 : rst_ff[k];
    end
  end
  assign r0_o = (rst_ff[r0_vec_indx_i]);
  assign r1_o = (rst_ff[r1_vec_indx_i]);
  assign r2_o = (rst_ff[r2_vec_indx_i])&(!((p0_vec_indx_i == r2_vec_indx_i)&&p0_busy_vld_i)||(p0_vec_indx_i==0));
  assign r3_o = (rst_ff[r3_vec_indx_i]) && (!((p0_vec_indx_i == r3_vec_indx_i)&&p0_busy_vld_i)||(p0_vec_indx_i==0));
  assign r4_o = (rst_ff[r4_vec_indx_i]);
  assign r5_o = (rst_ff[r5_vec_indx_i]);


endmodule
