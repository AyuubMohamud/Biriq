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
module AGU0 (
    input  wire logic        cpu_clock_i,
    input  wire logic        flush_i,
    output wire              agu_busy_o,
    input  wire              agu_vld_i,
    input  wire       [ 5:0] agu_rob_i,
    input  wire              agu_cmo_i,
    input  wire       [ 3:0] agu_op_i,
    input  wire       [31:0] agu_rs1_i,
    input  wire       [31:0] agu_rs2_i,
    input  wire       [31:0] agu_imm_i,
    input  wire       [ 5:0] agu_dest_i,
    // Load pipe
    input  wire              lsu_busy_i,
    output logic             lsu_vld_o,
    output logic      [ 5:0] lsu_rob_o,
    output logic             lsu_cmo_o,
    output logic      [ 3:0] lsu_op_o,
    output logic      [31:0] lsu_addr_o,
    output logic      [31:0] lsu_data_o,
    output logic      [ 5:0] lsu_dest_o,
    output logic      [31:0] lsu_sq_data_o,
    output logic      [ 3:0] lsu_sq_bm_o,

    output logic [31:0] excp_pc,
    output logic        excp_valid,
    output logic [ 3:0] excp_code_o,
    output logic [ 5:0] excp_rob,

    output wire logic [24:0] d_addr,
    output wire logic        d_write,
    input  wire logic        d_kill
);

  wire [31:0] lsu_addr = agu_rs1_i + agu_imm_i;
  wire [3:0] lsu_op = agu_op_i;
  wire [31:0] lsu_data = agu_rs2_i;
  wire isWrite = agu_op_i[3];
  logic [3:0] bm;
  logic [31:0] store_data;
  assign d_addr = lsu_addr[31:7];
  assign d_write = isWrite;
  assign agu_busy_o = lsu_busy_i;
  always_comb begin
    case ({
      lsu_addr[1:0], lsu_op[1:0]
    })
      4'b0000: begin
        bm = 4'b0001;
        store_data = lsu_data;
      end
      4'b0001: begin
        bm = 4'b0011;
        store_data = lsu_data;
      end
      4'b0010: begin
        bm = 4'b1111;
        store_data = lsu_data;
      end
      4'b0100: begin
        bm = 4'b0010;
        store_data = {16'd0, lsu_data[7:0], 8'd0};
      end
      4'b1000: begin
        bm = 4'b0100;
        store_data = {8'd0, lsu_data[7:0], 16'd0};
      end
      4'b1001: begin
        bm = 4'b1100;
        store_data = {lsu_data[15:0], 16'h0000};
      end
      4'b1100: begin
        bm = 4'b1000;
        store_data = {lsu_data[7:0], 24'd0};
      end
      default: begin
        bm = 4'b0110;
        store_data = 0;
      end
    endcase
  end
  wire misaligned = bm == 4'b0110;
  //always_ff @(posedge cpu_clock_i) begin
  //  if (flush_i) begin
  //    enqueue_en_o <= 0;
  //  end else if (!enqueue_full_i & !lq_full_i & lsu_vld & !misaligned & lsu_op[3] & !d_kill) begin
  //    enqueue_address_o <= lsu_addr[31:2];
  //    enqueue_bm_o <= bm;
  //    enqueue_data_o <= store_data;
  //    enqueue_io_o <= lsu_addr[31];
  //    enqueue_en_o <= 1;
  //    enqueue_rob_o <= lsu_rob[4:0];
  //  end else if (!enqueue_full_i) begin
  //    enqueue_en_o <= 0;
  //  end
  //end
  //
  //initial lq_valid_o = 0;
  //initial excp_valid = 0;
  //initial enqueue_en_o = 0;
  //always_ff @(posedge cpu_clock_i) begin
  //  if (flush_i) begin
  //    lq_valid_o <= 0;
  //  end else if (!enqueue_full_i & !lq_full_i & !lsu_op[3] & lsu_vld & (!d_kill | lsu_cmo)) begin
  //    lq_addr_o <= lsu_addr;
  //    lq_dest_o <= lsu_dest;
  //    lq_ld_type_o <= lsu_op[2:0];
  //    lq_rob_o <= lsu_rob;
  //    lq_valid_o <= 1;
  //    lq_cmo_o <= lsu_cmo;
  //    lq_bm_o <= bm;
  //  end else if (!lq_full_i) begin
  //    lq_valid_o <= 0;
  //  end
  //end

  always_ff @(posedge cpu_clock_i) begin
    if (flush_i) begin
      lsu_vld_o <= 1'b0;
    end else if (!lsu_busy_i & agu_vld_i & !((d_kill | misaligned) & !agu_cmo_i)) begin
      lsu_vld_o     <= 1'b1;
      lsu_rob_o     <= agu_rob_i;
      lsu_cmo_o     <= agu_cmo_i;
      lsu_op_o      <= agu_op_i;
      lsu_addr_o    <= lsu_addr;
      lsu_data_o    <= lsu_data;
      lsu_dest_o    <= agu_dest_i;
      lsu_sq_data_o <= store_data;
      lsu_sq_bm_o   <= bm;
    end else if (!lsu_busy_i) begin
      lsu_vld_o <= 1'b0;
    end
  end

  always_ff @(posedge cpu_clock_i) begin
    excp_pc <= lsu_addr;
    excp_valid <= agu_vld_i && !(lsu_busy_i) & ((bm == 4'b0110) | (d_kill)) & !agu_cmo_i;
    excp_rob <= agu_rob_i;
    excp_code_o <= d_kill ? isWrite ? 4'd7 : 4'd5 : isWrite ? 4'd6 : 4'd4;
  end
endmodule
