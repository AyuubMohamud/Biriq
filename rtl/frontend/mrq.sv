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
module mrq #(parameter ENABLE_C_EXTENSION = 1, parameter QUEUE_SZ = 8, parameter QUEUE_OFF = 0, parameter QUEUE_PASSTHROUGH = 1,
localparam PC_BITS = ENABLE_C_EXTENSION==1 ? 31 : 30,
localparam IDX_BITS = ENABLE_C_EXTENSION==1 ? 2 : 1)  (
    /* verilator lint_off UNUSED */
    input   wire logic                      core_clock_i,
    input   wire logic                      core_flush_i,
    /* verilator lint_on UNUSED */

    input   wire logic                      mrq_vld_i,
    input   wire logic [63:0]               mrq_instruction_i,
    input   wire logic [PC_BITS-1:0]        mrq_vpc_i,
    input   wire logic [3:0]                mrq_excp_code_i,
    input   wire logic                      mrq_excp_vld_i,
    input   wire logic [IDX_BITS-1:0]       mrq_btb_index_i,
    input   wire logic [1:0]                mrq_btb_btype_i,
    input   wire logic [1:0]                mrq_btb_bm_pred_i,
    input   wire logic [PC_BITS-1:0]        mrq_btb_target_i,
    input   wire logic                      mrq_btb_vld_i,
    input   wire logic                      mrq_btb_way_i,
    output  wire logic                      mrq_busy_o,

    output       logic                      nx_stage_vld_o,
    output       logic [63:0]               nx_stage_instruction_o,
    output       logic [PC_BITS-1:0]        nx_stage_vpc_o,
    output       logic [3:0]                nx_stage_excp_code_o,
    output       logic                      nx_stage_excp_vld_o,
    output       logic [IDX_BITS-1:0]       nx_stage_btb_index_o,
    output       logic [1:0]                nx_stage_btb_btype_o,
    output       logic [1:0]                nx_stage_btb_bm_pred_o,
    output       logic [PC_BITS-1:0]        nx_stage_btb_target_o,
    output       logic                      nx_stage_btb_vld_o,
    output       logic                      nx_stage_btb_way_o,
    input   wire logic                      nx_stage_busy_i
);
    /* verilator lint_off UNUSED */
    wire queue_write_condition;
    wire queue_read_condition;
    wire queue_full;
    wire queue_empty;

    wire [63:0]               queue_instruction_o;
    wire [PC_BITS-1:0]        queue_vpc_o;
    wire [3:0]                queue_excp_code_o;
    wire                      queue_excp_vld_o;
    wire [IDX_BITS-1:0]       queue_btb_index_o;
    wire [1:0]                queue_btb_btype_o;
    wire [1:0]                queue_btb_bm_pred_o;
    wire [PC_BITS-1:0]        queue_btb_target_o;
    wire                      queue_btb_vld_o;
    wire                      queue_btb_way_o;
    /* verilator lint_on UNUSED */
    generate if (QUEUE_OFF) begin : __queue_is_off
        assign nx_stage_vld_o           = mrq_vld_i;
        assign nx_stage_instruction_o   = mrq_instruction_i;
        assign nx_stage_vpc_o           = mrq_vpc_i;
        assign nx_stage_excp_code_o     = mrq_excp_code_i;
        assign nx_stage_excp_vld_o      = mrq_excp_vld_i;
        assign nx_stage_btb_index_o     = mrq_btb_index_i;
        assign nx_stage_btb_btype_o     = mrq_btb_btype_i;
        assign nx_stage_btb_bm_pred_o   = mrq_btb_bm_pred_i;
        assign nx_stage_btb_target_o    = mrq_btb_target_i;
        assign nx_stage_btb_vld_o       = mrq_btb_vld_i;
        assign nx_stage_btb_way_o       = mrq_btb_way_i;
        assign mrq_busy_o               = nx_stage_busy_i;
        assign queue_empty = 1'b0;
        assign queue_full = 1'b0;
        assign queue_read_condition = 1'b0;
        assign queue_write_condition = 1'b0;
        assign queue_instruction_o = 'b0;
        assign queue_vpc_o = 'b0;
        assign queue_excp_code_o = 'b0;
        assign queue_excp_vld_o = 'b0;
        assign queue_btb_index_o = 'b0;
        assign queue_btb_btype_o = 'b0;
        assign queue_btb_bm_pred_o = 'b0;
        assign queue_btb_target_o = 'b0;
        assign queue_btb_vld_o = 'b0;
        assign queue_btb_way_o = 'b0;
        end else if (!QUEUE_PASSTHROUGH) begin : __if_gen_queue
        assign queue_write_condition = mrq_vld_i&!queue_full;
        assign queue_read_condition = !nx_stage_busy_i&!queue_empty;
        assign mrq_busy_o = queue_full;
        assign nx_stage_vld_o = !queue_empty;
        sfifo2 #(QUEUE_SZ, 75+PC_BITS+IDX_BITS+PC_BITS) memory_response_queue (
            core_clock_i,
            core_flush_i,
            queue_write_condition,
            {mrq_instruction_i,
            mrq_vpc_i,
            mrq_excp_code_i,
            mrq_excp_vld_i,
            mrq_btb_index_i,
            mrq_btb_btype_i,
            mrq_btb_bm_pred_i,
            mrq_btb_target_i,
            mrq_btb_vld_i,
            mrq_btb_way_i},
            queue_full,
            queue_read_condition,
            {nx_stage_instruction_o,
            nx_stage_vpc_o,
            nx_stage_excp_code_o,
            nx_stage_excp_vld_o,
            nx_stage_btb_index_o,
            nx_stage_btb_btype_o,
            nx_stage_btb_bm_pred_o,
            nx_stage_btb_target_o,
            nx_stage_btb_vld_o,
            nx_stage_btb_way_o},
            queue_empty);
        assign queue_instruction_o = 'b0;
        assign queue_vpc_o = 'b0;
        assign queue_excp_code_o = 'b0;
        assign queue_excp_vld_o = 'b0;
        assign queue_btb_index_o = 'b0;
        assign queue_btb_btype_o = 'b0;
        assign queue_btb_bm_pred_o = 'b0;
        assign queue_btb_target_o = 'b0;
        assign queue_btb_vld_o = 'b0;
        assign queue_btb_way_o = 'b0;
    end else begin : __passthrough
        assign queue_write_condition = mrq_vld_i&!queue_full&nx_stage_busy_i;
        assign queue_read_condition = !nx_stage_busy_i&!queue_empty;
        assign mrq_busy_o = queue_full;
        assign nx_stage_vld_o = !(queue_empty&!mrq_vld_i);
        sfifo2 #(QUEUE_SZ, 75+PC_BITS+IDX_BITS+PC_BITS) memory_response_queue (
            core_clock_i,
            core_flush_i,
            queue_write_condition,
            {mrq_instruction_i,
            mrq_vpc_i,
            mrq_excp_code_i,
            mrq_excp_vld_i,
            mrq_btb_index_i,
            mrq_btb_btype_i,
            mrq_btb_bm_pred_i,
            mrq_btb_target_i,
            mrq_btb_vld_i,
            mrq_btb_way_i},
            queue_full,
            queue_read_condition,
            {queue_instruction_o,
            queue_vpc_o,
            queue_excp_code_o,
            queue_excp_vld_o,
            queue_btb_index_o,
            queue_btb_btype_o,
            queue_btb_bm_pred_o,
            queue_btb_target_o,
            queue_btb_vld_o,
            queue_btb_way_o},
            queue_empty);
        assign nx_stage_instruction_o   = queue_empty ? mrq_instruction_i   : queue_instruction_o;
        assign nx_stage_vpc_o           = queue_empty ? mrq_vpc_i           : queue_vpc_o;
        assign nx_stage_excp_code_o     = queue_empty ? mrq_excp_code_i     : queue_excp_code_o;
        assign nx_stage_excp_vld_o      = queue_empty ? mrq_excp_vld_i      : queue_excp_vld_o;
        assign nx_stage_btb_index_o     = queue_empty ? mrq_btb_index_i     : queue_btb_index_o;
        assign nx_stage_btb_btype_o     = queue_empty ? mrq_btb_btype_i     : queue_btb_btype_o;
        assign nx_stage_btb_bm_pred_o   = queue_empty ? mrq_btb_bm_pred_i   : queue_btb_bm_pred_o;
        assign nx_stage_btb_target_o    = queue_empty ? mrq_btb_target_i    : queue_btb_target_o;
        assign nx_stage_btb_vld_o       = queue_empty ? mrq_btb_vld_i       : queue_btb_vld_o;
        assign nx_stage_btb_way_o       = queue_empty ? mrq_btb_way_i       : queue_btb_way_o;
    end endgenerate
endmodule
