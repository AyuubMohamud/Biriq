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
    input   wire logic                          cpu_clock_i,
    input   wire logic                          flush_i,

    output  wire logic                          lsu_busy_o,
    input   wire logic                          lsu_vld_i,
    input   wire logic [5:0]                    lsu_rob_i,
    input   wire logic [3:0]                    lsu_op_i,
    input   wire logic [31:0]                   lsu_data_i,
    input   wire logic [31:0]                   lsu_addr_i,
    input   wire logic [5:0]                    lsu_dest_i,

    // Load pipe
    input   wire logic                          lq_full_i,
    output       logic [31:0]                   lq_addr_o,
    output       logic [2:0]                    lq_ld_type_o,
    output       logic [5:0]                    lq_dest_o,
    output       logic [5:0]                    lq_rob_o,
    output       logic                          lq_valid_o,
    // store pipe
    input   wire logic                          enqueue_full_i,
    output       logic [29:0]                   enqueue_address_o,
    output       logic [31:0]                   enqueue_data_o,
    output       logic [3:0]                    enqueue_bm_o,
    output       logic                          enqueue_io_o,
    output       logic                          enqueue_en_o,
    output       logic [4:0]                    enqueue_rob_o, 
    output       logic [29:0]                   conflict_address_o,
    output       logic [3:0]                    conflict_bm_o,

    output       logic [31:0]                   excp_pc,
    output       logic                          excp_valid,
    output       logic [3:0]                    excp_code_o,
    output       logic [5:0]                    excp_rob,

    output  wire logic [24:0]                   d_addr,
    output  wire logic                          d_write,
    input   wire logic                          d_kill
);
    wire logic                          lsu_vld;
    wire logic [5:0]                    lsu_rob;
    wire logic [3:0]                    lsu_op;
    wire logic [31:0]                   lsu_data;
    wire logic [31:0]                   lsu_addr;
    wire logic [5:0]                    lsu_dest;
    skdbf #(.DW(80)) agu0skidbuffer (cpu_clock_i, flush_i, lq_full_i|enqueue_full_i, {lsu_rob,lsu_op,lsu_data,lsu_addr,lsu_dest},
    lsu_vld, lsu_busy_o, {lsu_rob_i, lsu_op_i, lsu_data_i, lsu_addr_i, lsu_dest_i}, lsu_vld_i);
    wire isWrite = lsu_op[3];
    logic [3:0] bm; logic [31:0] store_data;
    assign d_addr = lsu_addr[31:7];
    assign d_write = isWrite;
    always_comb begin
        case ({lsu_addr[1:0], lsu_op[1:0]})
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
                store_data = {16'd0,lsu_data[7:0], 8'd0};
            end
            4'b1000: begin
                bm = 4'b0100;
                store_data = {8'd0,lsu_data[7:0], 16'd0};
            end
            4'b1001: begin
                bm = 4'b1100;
                store_data = {lsu_data[15:0], 16'h0000};
            end
            4'b1100: begin
                bm = 4'b1000; store_data = {lsu_data[7:0], 24'd0};
            end
            default: begin
                bm = 4'b0110; store_data = 0;
            end
        endcase
    end
    wire misaligned = bm==4'b0110;
    always_ff @(posedge cpu_clock_i) begin
        if (flush_i) begin
            enqueue_en_o <= 0;
        end else if (!enqueue_full_i&!lq_full_i&lsu_vld&!misaligned&lsu_op[3]&!d_kill) begin
            enqueue_address_o <= lsu_addr[31:2];
            enqueue_bm_o <= bm;
            enqueue_data_o <= store_data;
            enqueue_io_o <= lsu_addr[31];
            enqueue_en_o <= 1;
            enqueue_rob_o <= lsu_rob[4:0];
        end else if (!enqueue_full_i) begin
            enqueue_en_o <= 0;
        end
    end

    always_ff @(posedge cpu_clock_i) begin
        if (!enqueue_full_i&!lq_full_i&!lsu_op[3]&lsu_vld&!misaligned) begin
            conflict_address_o <= lsu_addr[31:2];
            conflict_bm_o <= bm;
        end
    end
    initial lq_valid_o = 0; initial excp_valid = 0; initial enqueue_en_o = 0;
    always_ff @(posedge cpu_clock_i) begin
        if (flush_i) begin
            lq_valid_o <= 0;
        end
        else if (!enqueue_full_i&!lq_full_i&!lsu_op[3]&lsu_vld&!d_kill) begin
            lq_addr_o <= lsu_addr;
            lq_dest_o <= lsu_dest;
            lq_ld_type_o <= lsu_op[2:0];
            lq_rob_o <= lsu_rob;
            lq_valid_o <= 1;
        end else if (!lq_full_i) begin
            lq_valid_o <= 0;
        end
    end

    always_ff @(posedge cpu_clock_i) begin
        excp_pc <= lsu_addr;
        excp_valid <= lsu_vld&&!(enqueue_full_i|lq_full_i)&((bm==4'b0110)|d_kill);
        excp_rob <= lsu_rob;
        excp_code_o <= d_kill ? isWrite ? 4'd7 : 4'd5 : isWrite ? 4'd6 : 4'd4;
    end
endmodule
