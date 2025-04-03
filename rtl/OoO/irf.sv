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
module irf (
    input wire logic        clk_i,
    input wire logic        p0_we_i,
    input wire logic [31:0] p0_we_data,
    input wire logic [ 5:0] p0_we_dest,

    input wire logic        p0_ex_i,
    input wire logic [31:0] p0_ex_data,
    input wire logic [ 5:0] p0_ex_dest,

    input wire logic        p1_we_i,
    input wire logic [31:0] p1_we_data,
    input wire logic [ 5:0] p1_we_dest,

    input wire logic        p1_ex_i,
    input wire logic [31:0] p1_ex_data,
    input wire logic [ 5:0] p1_ex_dest,

    input wire logic        p2_we_i,
    input wire logic [31:0] p2_we_data,
    input wire logic [ 5:0] p2_we_dest,

    input  wire logic [ 5:0] p0_rd_src,
    output logic      [31:0] p0_rd_datas,

    input  wire logic [ 5:0] p1_rd_src,
    output logic      [31:0] p1_rd_datas,

    input  wire logic [ 5:0] p2_rd_src,
    output logic      [31:0] p2_rd_datas,

    input  wire logic [ 5:0] p3_rd_src,
    output logic      [31:0] p3_rd_datas,

    input  wire logic [ 5:0] p4_rd_src,
    output logic      [31:0] p4_rd_datas,

    input  wire logic [ 5:0] p5_rd_src,
    output logic      [31:0] p5_rd_datas
);

  reg [31:0] file00[0:63];
  reg [31:0] file01[0:63];
  reg [31:0] file10[0:63];
  // forwarding network over ALUs
  wire p0_match_p0 = (p0_we_dest == p0_rd_src) && (p0_we_i);
  wire p0_match_p1 = (p1_we_dest == p0_rd_src) && (p1_we_i);
  wire p1_match_p0 = (p0_we_dest == p1_rd_src) && (p0_we_i);
  wire p1_match_p1 = (p1_we_dest == p1_rd_src) && (p1_we_i);
  wire p2_match_p0 = (p0_we_dest == p2_rd_src) && (p0_we_i);
  wire p2_match_p1 = (p1_we_dest == p2_rd_src) && (p1_we_i);
  wire p3_match_p0 = (p0_we_dest == p3_rd_src) && (p0_we_i);
  wire p3_match_p1 = (p1_we_dest == p3_rd_src) && (p1_we_i);
  wire p4_match_p0 = (p0_we_dest == p4_rd_src) && (p0_we_i);
  wire p4_match_p1 = (p1_we_dest == p4_rd_src) && (p1_we_i);
  wire p5_match_p0 = (p0_we_dest == p5_rd_src) && (p0_we_i);
  wire p5_match_p1 = (p1_we_dest == p5_rd_src) && (p1_we_i);
  assign p0_rd_datas = p0_match_p0 ? p0_we_data :  p0_match_p1 ? p1_we_data : (p0_ex_i)&&(p0_ex_dest==p0_rd_src) ? p0_ex_data : (p1_ex_i)&&(p1_ex_dest==p0_rd_src) ? p1_ex_data:
    file00[p0_rd_src] ^ file01[p0_rd_src] ^ file10[p0_rd_src];
  assign p1_rd_datas = p1_match_p0 ? p0_we_data :  p1_match_p1 ? p1_we_data : (p0_ex_i)&&(p0_ex_dest==p1_rd_src) ? p0_ex_data : (p1_ex_i)&&(p1_ex_dest==p1_rd_src) ? p1_ex_data:
    file00[p1_rd_src] ^ file01[p1_rd_src] ^ file10[p1_rd_src];
  assign p2_rd_datas = p2_match_p0 ? p0_we_data :  p2_match_p1 ? p1_we_data : (p0_ex_i)&&(p0_ex_dest==p2_rd_src) ? p0_ex_data : (p1_ex_i)&&(p1_ex_dest==p2_rd_src) ? p1_ex_data:
    file00[p2_rd_src] ^ file01[p2_rd_src] ^ file10[p2_rd_src];
  assign p3_rd_datas = p3_match_p0 ? p0_we_data :  p3_match_p1 ? p1_we_data : (p0_ex_i)&&(p0_ex_dest==p3_rd_src) ? p0_ex_data : (p1_ex_i)&&(p1_ex_dest==p3_rd_src) ? p1_ex_data:
    file00[p3_rd_src] ^ file01[p3_rd_src] ^ file10[p3_rd_src];
  assign p4_rd_datas = p4_match_p0 ? p0_we_data :  p4_match_p1 ? p1_we_data : (p0_ex_i)&&(p0_ex_dest==p4_rd_src) ? p0_ex_data : (p1_ex_i)&&(p1_ex_dest==p4_rd_src) ? p1_ex_data:
    file00[p4_rd_src] ^ file01[p4_rd_src] ^ file10[p4_rd_src];
  assign p5_rd_datas = p5_match_p0 ? p0_we_data :  p5_match_p1 ? p1_we_data : (p0_ex_i)&&(p0_ex_dest==p5_rd_src) ? p0_ex_data : (p1_ex_i)&&(p1_ex_dest==p5_rd_src) ? p1_ex_data:
    file00[p5_rd_src] ^ file01[p5_rd_src] ^ file10[p5_rd_src];

  always_ff @(posedge clk_i) begin
    if (p0_we_i) begin
      file00[p0_we_dest] <= p0_we_data ^ file01[p0_we_dest] ^ file10[p0_we_dest];
    end
    if (p1_we_i) begin
      file01[p1_we_dest] <= p1_we_data ^ file00[p1_we_dest] ^ file10[p1_we_dest];
    end
    if (p2_we_i) begin
      file10[p2_we_dest] <= p2_we_data ^ file00[p2_we_dest] ^ file01[p2_we_dest];
    end
  end
endmodule
