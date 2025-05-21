// This is the scheduler for most operations
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

`default_nettype none

module iiie_queue (
    input  wire        core_clock_i,
    input  wire        core_flush_i,
    input  wire  [5:0] p0_rob_i,
    input  wire  [5:0] p0_rs1_i,
    input  wire  [5:0] p0_rs2_i,
    input  wire        p0_in_order_i,
    input  wire        p0_oldest_i,
    input  wire        p0_restrict_to_u_i,
    input  wire        p0_restrict_to_v_i,
    input  wire        p0_vld_i,
    input  wire        p0_rs1_vld_i,
    input  wire        p0_rs2_vld_i,
    input  wire        p0_rs1_rdy,
    input  wire        p0_rs2_rdy,
    input  wire  [5:0] p1_rob_i,
    input  wire  [5:0] p1_rs1_i,
    input  wire  [5:0] p1_rs2_i,
    input  wire        p1_in_order_i,
    input  wire        p1_oldest_i,
    input  wire        p1_restrict_to_u_i,
    input  wire        p1_restrict_to_v_i,
    input  wire        p1_vld_i,
    input  wire        p1_rs1_vld_i,
    input  wire        p1_rs2_vld_i,
    input  wire        p1_rs1_rdy,
    input  wire        p1_rs2_rdy,
    output wire        p0_busy_o,
    output wire        p1_busy_o,
    output logic       u_vld_o,
    output logic [5:0] u_rob_o,
    output logic [5:0] u_rs1_o,
    output logic [5:0] u_rs2_o,
    input  wire        v_busy_i,
    output logic       v_vld_o,
    output logic [5:0] v_rob_o,
    output logic [5:0] v_rs1_o,
    output logic [5:0] v_rs2_o,
    // U pipe wake
    input  wire  [5:0] eu0_wk,
    input  wire        eu0_vld,
    // V pipe early ALU wake
    input  wire  [5:0] eu1_wk,
    input  wire        eu1_vld,
    // V pipe early forward wake
    input  wire  [5:0] eu2_wk,
    input  wire        eu2_vld,
    // V pipe memory wake
    input  wire  [5:0] eu3_wk,
    input  wire        eu3_vld,
    // oldest instruction
    input  wire  [4:0] oldest_instruction
);
  reg [5:0] ShQueueCAM1[0:9];  // Store Data
  reg [5:0] ShQueueCAM0[0:9];
  reg [5:0] ShQueueRAM[0:9];  // ROB ID
  reg [9:0] u_restrict;
  reg [9:0] v_restrict;
  reg [9:0] in_order; // Any instructions marked like this execute in order with other marked instructions
  reg [9:0] oldest; // Any instruction with this characteristic can only be released when its the oldest one
  reg [9:0] vld = 0;
  reg [9:0] AV1;
  reg [9:0] AV2;
  wire [9:0] AV1l;
  wire [9:0] AV2l;
  wire [9:0] shift;
  wire [9:0] shift_two;
  wire [9:0] caio;
  wire [9:0] data_rdy;
  wire [9:0] vldl;
  logic [9:0] ddec;
  logic [9:0] ddec2;

  assign shift[0] = !vld[0];
  assign shift[1] = !(vld[1] & vld[0]);
  assign shift[2] = !(vld[2] & vld[1] & vld[0]);
  assign shift[3] = !(vld[3] & vld[2] & vld[1] & vld[0]);
  assign shift[4] = !(vld[4] & vld[3] & vld[2] & vld[1] & vld[0]);
  assign shift[5] = !(vld[5] & vld[4] & vld[3] & vld[2] & vld[1] & vld[0]);
  assign shift[6] = !(vld[6] & vld[5] & vld[4] & vld[3] & vld[2] & vld[1] & vld[0]);
  assign shift[7] = !(vld[7] & vld[6] & vld[5] & vld[4] & vld[3] & vld[2] & vld[1] & vld[0]);
  assign shift[8] = !(vld[8] & vld[7] & vld[6] & vld[5] & vld[4] & vld[3] & vld[2] & vld[1] & vld[0]);
  assign shift[9] = !(vld[9] & vld[8] & vld[7] & vld[6] & vld[5] & vld[4] & vld[3] & vld[2] & vld[1] & vld[0]);
  assign shift_two[0] = !vld[1] & shift[0];
  assign shift_two[1] = (!vld[1] & shift[0]) | (!vld[2] & shift[1]);
  assign shift_two[2] = (!vld[1] & shift[0]) | (!vld[2] & shift[1]) | (!vld[3] & shift[2]);
  assign shift_two[3] = (!vld[1]&shift[0])|(!vld[2]&shift[1])|(!vld[3]&shift[2])|(!vld[4]&shift[3]);
  assign shift_two[4] = (!vld[1]&shift[0])|(!vld[2]&shift[1])|(!vld[3]&shift[2])|(!vld[4]&shift[3])|(!vld[5]&shift[4]);
  assign shift_two[5] = (!vld[1]&shift[0])|(!vld[2]&shift[1])|(!vld[3]&shift[2])|(!vld[4]&shift[3])|(!vld[5]&shift[4])|(!vld[6]&shift[5]);
  assign shift_two[6] = (!vld[1]&shift[0])|(!vld[2]&shift[1])|(!vld[3]&shift[2])|(!vld[4]&shift[3])|(!vld[5]&shift[4])|(!vld[6]&shift[5])|(!vld[7]&shift[6]);
  assign shift_two[7] = (!vld[1]&shift[0])|(!vld[2]&shift[1])|(!vld[3]&shift[2])|(!vld[4]&shift[3])|(!vld[5]&shift[4])|(!vld[6]&shift[5])|(!vld[7]&shift[6])|(!vld[8]&shift[7]);
  assign shift_two[8] = (!vld[1]&shift[0])|(!vld[2]&shift[1])|(!vld[3]&shift[2])|(!vld[4]&shift[3])|(!vld[5]&shift[4])|(!vld[6]&shift[5])|(!vld[7]&shift[6])|(!vld[8]&shift[7])|(!vld[9]&shift[8]);
  assign shift_two[9] = (!vld[1]&shift[0])|(!vld[2]&shift[1])|(!vld[3]&shift[2])|(!vld[4]&shift[3])|(!vld[5]&shift[4])|(!vld[6]&shift[5])|(!vld[7]&shift[6])|(!vld[8]&shift[7])|(!vld[9]&shift[8]);
  assign caio[0] = 1'b1;
  assign caio[1] = !(vld[0] & in_order[0]);
  assign caio[2] = !(vld[0] & in_order[0]) & !(vld[1] & in_order[1]);
  assign caio[3] = !(vld[0] & in_order[0]) & !(vld[1] & in_order[1]) & !(vld[2] & in_order[2]);
  assign caio[4] = !(vld[0] & in_order[0]) & !(vld[1] & in_order[1]) & !(vld[2] & in_order[2]) & !(vld[3]&in_order[3]);
  assign caio[5] = !(vld[0] & in_order[0]) & !(vld[1] & in_order[1]) & !(vld[2] & in_order[2]) & !(vld[3]&in_order[3]) & !(vld[4]&in_order[4]);
  assign caio[6] = !(vld[0] & in_order[0]) & !(vld[1] & in_order[1]) & !(vld[2] & in_order[2]) & !(vld[3]&in_order[3]) & !(vld[4]&in_order[4]) & !(vld[5]&in_order[5]);
  assign caio[7] = !(vld[0] & in_order[0]) & !(vld[1] & in_order[1]) & !(vld[2] & in_order[2]) & !(vld[3]&in_order[3]) & !(vld[4]&in_order[4]) & !(vld[5]&in_order[5]) & !(vld[6]&in_order[6]);
  assign caio[8] = !(vld[0] & in_order[0]) & !(vld[1] & in_order[1]) & !(vld[2] & in_order[2]) & !(vld[3]&in_order[3]) & !(vld[4]&in_order[4]) & !(vld[5]&in_order[5]) & !(vld[6]&in_order[6]) & !(vld[7]&in_order[7]);
  assign caio[9] = !(vld[0] & in_order[0]) & !(vld[1] & in_order[1]) & !(vld[2] & in_order[2]) & !(vld[3]&in_order[3]) & !(vld[4]&in_order[4]) & !(vld[5]&in_order[5]) & !(vld[6]&in_order[6]) & !(vld[7]&in_order[7]) & !(vld[8]&in_order[8]);

  assign p0_busy_o = !shift[9];
  assign p1_busy_o = !shift_two[9];

  wire [9:0] CMPy;
  wire [9:0] CMPs;
  wire [9:0] is_oldest;
  generate
    for (genvar i = 0; i < 10; i++) begin : _0
      assign CMPy[i] = (((ShQueueCAM1[i] == eu0_wk) & eu0_vld) | ((ShQueueCAM1[i] == eu1_wk) & eu1_vld) | ((ShQueueCAM1[i] == eu2_wk) & eu2_vld)| ((ShQueueCAM1[i] == eu3_wk) & eu3_vld)) & vld[i];
    end
  endgenerate
  generate
    for (genvar i = 0; i < 10; i++) begin : _oldest
      assign is_oldest[i] = ShQueueRAM[i][4:0] == oldest_instruction;
    end
  endgenerate

  generate
    for (genvar i = 0; i < 10; i++) begin : _1
      assign AV2l[i] = (AV2[i] | CMPy[i]) & !core_flush_i;
    end
  endgenerate
  generate
    for (genvar i = 0; i < 10; i++) begin : _9
      assign AV1l[i] = (AV1[i] | CMPs[i]) & !core_flush_i;
    end
  endgenerate
  generate
    for (genvar i = 0; i < 10; i++) begin : _______
      assign CMPs[i] = (((ShQueueCAM0[i] == eu0_wk) & eu0_vld) | ((ShQueueCAM0[i] == eu1_wk) & eu1_vld) | ((ShQueueCAM0[i] == eu2_wk) & eu2_vld)  | ((ShQueueCAM0[i] == eu3_wk) & eu3_vld))& vld[i];
    end
  endgenerate
  generate
    for (genvar i = 0; i < 10; i++) begin : _2
      assign vldl[i] = vld[i] & !ddec[i] & !ddec2[i] & !core_flush_i;
    end
  endgenerate
  generate
    for (genvar i = 0; i < 10; i++) begin : _3
      assign data_rdy[i] = vld[i] & AV2l[i] & AV1l[i] & !(!caio[i] & in_order[i]) & !(!is_oldest[i]&oldest[i]) & !core_flush_i;
    end
  endgenerate
  generate
    for (genvar i = 0; i < 8; i++) begin : _4
      always_ff @(posedge core_clock_i) begin
        vld[i] <= shift_two[i] ? vldl[i+2] : shift[i] ? vldl[i+1] : vldl[i];
      end
    end
  endgenerate
  generate
    for (genvar i = 0; i < 8; i++) begin : _5
      always_ff @(posedge core_clock_i) begin
        AV2[i] <= shift_two[i] ? AV2l[i+2] : shift[i] ? AV2l[i+1] : AV2l[i];
      end
    end
  endgenerate
  generate
    for (genvar i = 0; i < 8; i++) begin : _13
      always_ff @(posedge core_clock_i) begin
        v_restrict[i] <= shift_two[i] ? v_restrict[i+2] : shift[i] ? v_restrict[i+1] : v_restrict[i];
      end
    end
  endgenerate
  generate
    for (genvar i = 0; i < 8; i++) begin : _14
      always_ff @(posedge core_clock_i) begin
        u_restrict[i] <= shift_two[i] ? u_restrict[i+2] : shift[i] ? u_restrict[i+1] : u_restrict[i];
      end
    end
  endgenerate
  generate
    for (genvar i = 0; i < 8; i++) begin : _16
      always_ff @(posedge core_clock_i) begin
        oldest[i] <= shift_two[i] ? oldest[i+2] : shift[i] ? oldest[i+1] : oldest[i];
      end
    end
  endgenerate
  generate
    for (genvar i = 0; i < 8; i++) begin : _17
      always_ff @(posedge core_clock_i) begin
        in_order[i] <= shift_two[i] ? in_order[i+2] : shift[i] ? in_order[i+1] : in_order[i];
      end
    end
  endgenerate
  generate
    for (genvar i = 0; i < 8; i++) begin : _10
      always_ff @(posedge core_clock_i) begin
        AV1[i] <= shift_two[i] ? AV1l[i+2] : shift[i] ? AV1l[i+1] : AV1l[i];
      end
    end
  endgenerate
  generate
    for (genvar i = 0; i < 8; i++) begin : _6
      always_ff @(posedge core_clock_i) begin
        ShQueueRAM[i] <= shift_two[i] ? ShQueueRAM[i+2] : shift[i] ? ShQueueRAM[i+1] : ShQueueRAM[i];
      end
    end
  endgenerate
  generate
    for (genvar i = 0; i < 8; i++) begin : _7
      always_ff @(posedge core_clock_i) begin
        ShQueueCAM1[i] <= shift_two[i] ? ShQueueCAM1[i+2] : shift[i] ? ShQueueCAM1[i+1] : ShQueueCAM1[i];
      end
    end
  endgenerate
  generate
    for (genvar i = 0; i < 8; i++) begin : _11
      always_ff @(posedge core_clock_i) begin
        ShQueueCAM0[i] <= shift_two[i] ? ShQueueCAM0[i+2] : shift[i] ? ShQueueCAM0[i+1] : ShQueueCAM0[i];
      end
    end
  endgenerate
  wire p0_av1_temp;
  assign p0_av1_temp = ((((p0_rs1_i == eu0_wk) & eu0_vld) | ((p0_rs1_i == eu1_wk) & eu1_vld) | ((p0_rs1_i == eu2_wk) & eu2_vld) | ((p0_rs1_i == eu3_wk) & eu3_vld)))|p0_rs1_rdy|!p0_rs1_vld_i;
  wire p1_av1_temp;
  assign p1_av1_temp = ((((p1_rs1_i == eu0_wk) & eu0_vld) | ((p1_rs1_i == eu1_wk) & eu1_vld) | ((p1_rs1_i == eu2_wk) & eu2_vld) | ((p1_rs1_i == eu3_wk) & eu3_vld)))|p1_rs1_rdy|!p1_rs1_vld_i;

  wire p0_av2_temp;
  assign p0_av2_temp = (((p0_rs2_i == eu0_wk) & eu0_vld) | ((p0_rs2_i == eu1_wk) & eu1_vld) | ((p0_rs2_i == eu2_wk) & eu2_vld) | ((p0_rs2_i == eu3_wk) & eu3_vld))|p0_rs2_rdy||!p0_rs2_vld_i;
  wire p1_av2_temp;
  assign p1_av2_temp = ((((p1_rs2_i == eu0_wk)& eu0_vld) | ((p1_rs2_i == eu1_wk) & eu1_vld) | ((p1_rs2_i == eu2_wk) & eu2_vld) | ((p1_rs2_i == eu3_wk) & eu3_vld)))|p1_rs2_rdy|!p1_rs2_vld_i;

  always_ff @(posedge core_clock_i) begin
    ShQueueCAM1[9] <= shift_two[9] ? p1_rs2_i : shift[9] ? p0_rs2_i : ShQueueCAM1[9];
    ShQueueCAM1[8] <= shift_two[8] ? p0_rs2_i : shift[8] ? ShQueueCAM1[9] : ShQueueCAM1[8];
    ShQueueCAM0[9] <= shift_two[9] ? p1_rs1_i : shift[9] ? p0_rs1_i : ShQueueCAM0[9];
    ShQueueCAM0[8] <= shift_two[8] ? p0_rs1_i : shift[8] ? ShQueueCAM0[9] : ShQueueCAM0[8];
    ShQueueRAM[9] <= shift_two[9] ? p1_rob_i : shift[9] ? p0_rob_i : ShQueueRAM[9];
    ShQueueRAM[8] <= shift_two[8] ? p0_rob_i : shift[8] ? ShQueueRAM[9] : ShQueueRAM[8];
    vld[9] <= shift_two[9] ? p1_vld_i & !core_flush_i : shift[9] ? p0_vld_i & !core_flush_i : vldl[9];
    vld[8] <= shift_two[8] ? p0_vld_i & !core_flush_i : shift[8] ? vldl[9] : vldl[8];
    v_restrict[9] <= shift_two[9] ? p1_restrict_to_v_i : shift[9] ? p0_restrict_to_v_i : v_restrict[9];
    v_restrict[8] <= shift_two[8] ? p0_restrict_to_v_i : shift[8] ? v_restrict[9] : v_restrict[8];
    u_restrict[9] <= shift_two[9] ? p1_restrict_to_u_i : shift[9] ? p0_restrict_to_u_i : u_restrict[9];
    u_restrict[8] <= shift_two[8] ? p0_restrict_to_u_i : shift[8] ? u_restrict[9] : u_restrict[8];
    oldest[9] <= shift_two[9] ? p1_oldest_i : shift[9] ? p0_oldest_i : oldest[9];
    oldest[8] <= shift_two[8] ? p0_oldest_i : shift[8] ? oldest[9] : oldest[8];
    in_order[9] <= shift_two[9] ? p1_in_order_i : shift[9] ? p0_in_order_i : in_order[9];
    in_order[8] <= shift_two[8] ? p0_in_order_i : shift[8] ? in_order[9] : in_order[8];
    AV2[9] <= shift_two[9] ? p1_av2_temp&!core_flush_i&p1_vld_i : shift[9] ? p0_av2_temp&!core_flush_i&p0_vld_i : AV2l[9];
    AV2[8] <= shift_two[8] ? p0_av2_temp & !core_flush_i & p0_vld_i : shift[8] ? AV2l[9] : AV2l[8];
    AV1[9] <= shift_two[9] ? p1_av1_temp&!core_flush_i&p1_vld_i : shift[9] ? p0_av1_temp&!core_flush_i&p0_vld_i : AV1l[9];
    AV1[8] <= shift_two[8] ? p0_av1_temp & !core_flush_i & p0_vld_i : shift[8] ? AV1l[9] : AV1l[8];
  end
  logic [5:0] rs1;
  logic [5:0] rs2;
  logic [5:0] rob;
  wire  [9:0] initial_ready;
  assign initial_ready = data_rdy & ~u_restrict & {10{~v_busy_i}};
  always_comb begin
    casez (initial_ready)
      10'bzzzzzzzzz1: begin
        ddec = 10'b0000000001;
        rs1  = ShQueueCAM0[0];
        rs2  = ShQueueCAM1[0];
        rob  = ShQueueRAM[0];
      end
      10'bzzzzzzzz10: begin
        ddec = 10'b0000000010;
        rs1  = ShQueueCAM0[1];
        rs2  = ShQueueCAM1[1];
        rob  = ShQueueRAM[1];
      end
      10'bzzzzzzz100: begin
        ddec = 10'b0000000100;
        rs1  = ShQueueCAM0[2];
        rs2  = ShQueueCAM1[2];
        rob  = ShQueueRAM[2];
      end
      10'bzzzzzz1000: begin
        ddec = 10'b0000001000;
        rs1  = ShQueueCAM0[3];
        rs2  = ShQueueCAM1[3];
        rob  = ShQueueRAM[3];
      end
      10'bzzzzz10000: begin
        ddec = 10'b0000010000;
        rs1  = ShQueueCAM0[4];
        rs2  = ShQueueCAM1[4];
        rob  = ShQueueRAM[4];
      end
      10'bzzzz100000: begin
        ddec = 10'b0000100000;
        rs1  = ShQueueCAM0[5];
        rs2  = ShQueueCAM1[5];
        rob  = ShQueueRAM[5];
      end
      10'bzzz1000000: begin
        ddec = 10'b0001000000;
        rs1  = ShQueueCAM0[6];
        rs2  = ShQueueCAM1[6];
        rob  = ShQueueRAM[6];
      end
      10'bzz10000000: begin
        ddec = 10'b0010000000;
        rs1  = ShQueueCAM0[7];
        rs2  = ShQueueCAM1[7];
        rob  = ShQueueRAM[7];
      end
      10'bz100000000: begin
        ddec = 10'b0100000000;
        rs1  = ShQueueCAM0[8];
        rs2  = ShQueueCAM1[8];
        rob  = ShQueueRAM[8];
      end
      10'b1000000000: begin
        ddec = 10'b1000000000;
        rs1  = ShQueueCAM0[9];
        rs2  = ShQueueCAM1[9];
        rob  = ShQueueRAM[9];
      end
      default: begin
        ddec = 10'h000;
        rs1  = 'x;
        rs2  = 'x;
        rob  = 'x;
      end
    endcase
  end
  wire [9:0] second_ready;
  assign second_ready = data_rdy & ~ddec & ~v_restrict;
  logic [5:0] rs12;
  logic [5:0] rs22;
  logic [5:0] rob2;
  always_comb begin
    casez (second_ready)
      10'bzzzzzzzzz1: begin
        ddec2 = 10'b0000000001;
        rs12  = ShQueueCAM0[0];
        rs22  = ShQueueCAM1[0];
        rob2  = ShQueueRAM[0];
      end
      10'bzzzzzzzz10: begin
        ddec2 = 10'b0000000010;
        rs12  = ShQueueCAM0[1];
        rs22  = ShQueueCAM1[1];
        rob2  = ShQueueRAM[1];
      end
      10'bzzzzzzz100: begin
        ddec2 = 10'b0000000100;
        rs12  = ShQueueCAM0[2];
        rs22  = ShQueueCAM1[2];
        rob2  = ShQueueRAM[2];
      end
      10'bzzzzzz1000: begin
        ddec2 = 10'b0000001000;
        rs12  = ShQueueCAM0[3];
        rs22  = ShQueueCAM1[3];
        rob2  = ShQueueRAM[3];
      end
      10'bzzzzz10000: begin
        ddec2 = 10'b0000010000;
        rs12  = ShQueueCAM0[4];
        rs22  = ShQueueCAM1[4];
        rob2  = ShQueueRAM[4];
      end
      10'bzzzz100000: begin
        ddec2 = 10'b0000100000;
        rs12  = ShQueueCAM0[5];
        rs22  = ShQueueCAM1[5];
        rob2  = ShQueueRAM[5];
      end
      10'bzzz1000000: begin
        ddec2 = 10'b0001000000;
        rs12  = ShQueueCAM0[6];
        rs22  = ShQueueCAM1[6];
        rob2  = ShQueueRAM[6];
      end
      10'bzz10000000: begin
        ddec2 = 10'b0010000000;
        rs12  = ShQueueCAM0[7];
        rs22  = ShQueueCAM1[7];
        rob2  = ShQueueRAM[7];
      end
      10'bz100000000: begin
        ddec2 = 10'b0100000000;
        rs12  = ShQueueCAM0[8];
        rs22  = ShQueueCAM1[8];
        rob2  = ShQueueRAM[8];
      end
      10'b1000000000: begin
        ddec2 = 10'b1000000000;
        rs12  = ShQueueCAM0[9];
        rs22  = ShQueueCAM1[9];
        rob2  = ShQueueRAM[9];
      end
      default: begin
        ddec2 = 10'h000;
        rs12  = 'x;
        rs22  = 'x;
        rob2  = 'x;
      end
    endcase
  end
  initial v_vld_o = 0;
  initial u_vld_o = 0;
  always_ff @(posedge core_clock_i)
    if (core_flush_i) begin
      u_vld_o <= 1'b0;
    end else if (|second_ready) begin
      u_rob_o <= rob2;
      u_rs1_o <= rs12;
      u_rs2_o <= rs22;
      u_vld_o <= 1'b1;
    end else begin
      u_vld_o <= 1'b0;
    end
  always_ff @(posedge core_clock_i)
    if (core_flush_i) begin
      v_vld_o <= 1'b0;
    end else if ((|initial_ready)) begin
      v_rob_o <= rob;
      v_rs1_o <= rs1;
      v_rs2_o <= rs2;
      v_vld_o <= 1'b1;
    end else if (!v_busy_i) begin
      v_vld_o <= 1'b0;
    end
endmodule
