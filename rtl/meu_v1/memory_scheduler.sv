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
module memory_scheduler (
    input  wire         cpu_clk_i,
    input  wire         flush_i,
    // interface from renamer
    input  wire         renamer_pkt_vld_i,
    input  wire  [ 5:0] pkt0_rs1_i,
    input  wire  [ 5:0] pkt0_rs2_i,
    input  wire  [ 5:0] pkt0_dest_i,
    input  wire  [31:0] pkt0_immediate_i,
    input  wire  [ 5:0] pkt0_ios_type_i,
    input  wire  [ 2:0] pkt0_ios_opcode_i,
    input  wire  [ 4:0] pkt0_rob_i,
    input  wire         pkt0_vld_i,
    input  wire  [ 5:0] pkt1_rs1_i,
    input  wire  [ 5:0] pkt1_rs2_i,
    input  wire  [ 5:0] pkt1_dest_i,
    input  wire  [31:0] pkt1_immediate_i,
    input  wire  [ 5:0] pkt1_ios_type_i,
    input  wire  [ 2:0] pkt1_ios_opcode_i,
    input  wire         pkt1_vld_i,
    output wire         full,
    // register ready status
    output wire  [ 5:0] r4_vec_indx_o,
    input  wire         r4_i,
    output wire  [ 5:0] r5_vec_indx_o,
    input  wire         r5_i,
    input  wire         meu_busy_i,
    output logic        meu_vld_o,
    output logic [ 5:0] meu_rob_o,
    output logic [ 5:0] meu_type_o,
    output logic [ 2:0] meu_op_o,
    output logic [31:0] meu_imm_o,
    output logic [ 5:0] meu_rs1_o,
    output logic [ 5:0] meu_rs2_o,
    output logic [ 5:0] meu_dest_o
);
  initial meu_vld_o = 0;
  wire        empty;
  wire        issue;
  wire [ 5:0] pkt0_rs1;
  wire [ 5:0] pkt0_rs2;
  wire [ 5:0] pkt0_dest;
  wire [31:0] pkt0_immediate;
  wire [ 5:0] pkt0_ios_type;
  wire [ 2:0] pkt0_ios_opcode;
  wire [ 4:0] pkt0_rob;
  wire        pkt0_vld;
  wire [ 5:0] pkt1_rs1;
  wire [ 5:0] pkt1_rs2;
  wire [ 5:0] pkt1_dest;
  wire [31:0] pkt1_immediate;
  wire [ 5:0] pkt1_ios_type;
  wire [ 2:0] pkt1_ios_opcode;
  wire        pkt1_vld;
  sfifo2 #(
      .DW(125),
      .FW(8)
  ) memfifo (
      cpu_clk_i,
      flush_i,
      !full & renamer_pkt_vld_i,
      {
        pkt0_rs1_i,
        pkt0_rs2_i,
        pkt0_dest_i,
        pkt0_immediate_i,
        pkt0_ios_type_i,
        pkt0_ios_opcode_i,
        pkt0_rob_i,
        pkt0_vld_i,
        pkt1_rs1_i,
        pkt1_rs2_i,
        pkt1_dest_i,
        pkt1_immediate_i,
        pkt1_ios_type_i,
        pkt1_ios_opcode_i,
        pkt1_vld_i
      },
      full,
      issue,
      {
        pkt0_rs1,
        pkt0_rs2,
        pkt0_dest,
        pkt0_immediate,
        pkt0_ios_type,
        pkt0_ios_opcode,
        pkt0_rob,
        pkt0_vld,
        pkt1_rs1,
        pkt1_rs2,
        pkt1_dest,
        pkt1_immediate,
        pkt1_ios_type,
        pkt1_ios_opcode,
        pkt1_vld
      },
      empty
  );

  reg packet_select;
  wire initial_packet_select = !pkt0_vld & pkt1_vld;
  wire actual_packet_select = initial_packet_select | packet_select;

  wire [5:0] packet_rs1 = actual_packet_select ? pkt1_rs1 : pkt0_rs1;
  wire [5:0] packet_rs2 = actual_packet_select ? pkt1_rs2 : pkt0_rs2;
  wire [5:0] packet_dest = actual_packet_select ? pkt1_dest : pkt0_dest;
  wire [31:0] packet_imm = actual_packet_select ? pkt1_immediate : pkt0_immediate;
  wire [5:0] packet_type = actual_packet_select ? pkt1_ios_type : pkt0_ios_type;
  wire [2:0] packet_opcode = actual_packet_select ? pkt1_ios_opcode : pkt0_ios_opcode;
  wire [5:0] packet_rob = actual_packet_select ? {pkt0_rob[4:0], 1'b1} : {pkt0_rob[4:0], 1'b0};
  wire packet_rs2_dependant = packet_type[3];  // a store
  assign r4_vec_indx_o = packet_rs1;
  assign r5_vec_indx_o = packet_rs2;
  wire packet_is_issueable = r4_i & !(!r5_i & packet_rs2_dependant) & !meu_busy_i & !empty;
  assign issue = (pkt0_vld&!pkt1_vld)||(!pkt0_vld&pkt1_vld) ? packet_is_issueable : packet_is_issueable&packet_select;

  always_ff @(posedge cpu_clk_i)
    if (flush_i) meu_vld_o <= 0;
    else if (packet_is_issueable) meu_vld_o <= 1;
    else if (!meu_busy_i) meu_vld_o <= 0;

  always_ff @(posedge cpu_clk_i)
    if (packet_is_issueable) begin
      meu_rob_o  <= packet_rob;
      meu_type_o <= packet_type;
      meu_op_o   <= packet_opcode;
      meu_rs1_o  <= packet_rs1;
      meu_rs2_o  <= packet_rs2;
      meu_dest_o <= packet_dest;
      meu_imm_o  <= packet_imm;
    end

  always_ff @(posedge cpu_clk_i)
    if (flush_i) packet_select <= 1'b0;
    else if (packet_is_issueable)
      packet_select <= pkt0_vld&pkt1_vld ? ~packet_select : (pkt0_vld&!pkt1_vld)|(!pkt0_vld&pkt1_vld) ? 1'b0 : 1'b1;

endmodule
