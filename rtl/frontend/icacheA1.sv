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
module icacheA1 #(parameter ENABLE_C_EXTENSION = 1,
localparam PC_BITS = ENABLE_C_EXTENSION==1 ? 31 : 30,
localparam IDX_BITS = ENABLE_C_EXTENSION==1 ? 2 : 1) (
    input   wire logic                      core_clock_i,
    input   wire logic                      core_flush_i,

    input   wire logic                      icache_vld_i, //! IF2 valid next cycle
    input   wire logic [PC_BITS-1:0]        icache_ppc_i, //! Only used for Cache
    input   wire logic [IDX_BITS-1:0]       icache_btb_index_i,
    input   wire logic [1:0]                icache_btb_btype_i, //! Branch type: 00 = Cond, 01 = Indirect, 10 - Jump, 11 - Ret
    input   wire logic [1:0]                icache_btb_bm_pred_i, //! Bimodal counter prediction
    input   wire logic [PC_BITS-1:0]        icache_btb_target_i, //! Predicted target if branch is taken
    input   wire logic                      icache_btb_vld_i,
    input   wire logic                      icache_btb_way_i,
    output  wire logic                      icache_busy_o,

    // decode
    output       logic                      dec_vld_o,
    output       logic [63:0]               dec_instruction_o,
    output       logic [PC_BITS-1:0]        dec_vpc_o,
    output       logic [3:0]                dec_excp_code_o,
    output       logic                      dec_excp_vld_o,
    output       logic [IDX_BITS-1:0]       dec_btb_index_o,
    output       logic [1:0]                dec_btb_btype_o, //! Branch type: 00 = Cond, 01 = Indirect, 10 - Jump, 11 - Ret
    output       logic [1:0]                dec_btb_bm_pred_o, //! Bimodal counter prediction
    output       logic [PC_BITS-1:0]        dec_btb_target_o, //! Predicted target if branch is taken
    output       logic                      dec_btb_vld_o,
    output       logic                      dec_btb_way_o,
    input   wire logic                      dec_busy_i,

    input   wire logic                      cache_flush_i,
    output  wire logic                      flush_resp_o,

    // TileLink Bus Master Uncached Heavyweight
    output       logic [2:0]                icache_a_opcode,
    output       logic [2:0]                icache_a_param,
    output       logic [3:0]                icache_a_size,
    output       logic [31:0]               icache_a_address,
    output       logic [3:0]                icache_a_mask,
    output       logic [31:0]               icache_a_data,
    output       logic                      icache_a_corrupt,
    output       logic                      icache_a_valid,
    input   wire logic                      icache_a_ready,
    /* verilator lint_off UNUSEDSIGNAL */
    input   wire logic [2:0]                icache_d_opcode,
    input   wire logic [1:0]                icache_d_param,
    input   wire logic [3:0]                icache_d_size,
    input   wire logic                      icache_d_denied,
    /* verilator lint_on UNUSEDSIGNAL */
    input   wire logic [31:0]               icache_d_data,
    /* verilator lint_off UNUSEDSIGNAL */
    input   wire logic                      icache_d_corrupt,
    /* verilator lint_on UNUSEDSIGNAL */
    input   wire logic                      icache_d_valid,
    output  wire logic                      icache_d_ready,

    output  wire logic [24:0]               i_addr,
    input   wire logic                      i_kill
);
    initial icache_a_valid = 0;
    wire [PC_BITS-1:0] working_addr; wire [PC_BITS-1:0] working_target; wire [1:0] working_type; wire working_btb_vld; wire [1:0] working_bimodal_prediction;
    wire btb_way;
    wire working_valid; wire [IDX_BITS-1:0] working_btb_index;
    localparam IDLE = 2'b00;
    localparam MISS_REQ = 2'b01;
    localparam MISS_RESP = 2'b10;
    localparam CFLUSH = 2'b11;
    reg [1:0] cache_fsm = IDLE;
    wire req_not_found;
    wire miss = (cache_fsm==IDLE)&(cache_flush_i|req_not_found);
    skdbf #(.DW(PC_BITS+PC_BITS+IDX_BITS+1+2+1+2)) skidbuffer (
        core_clock_i, core_flush_i, dec_busy_i|(cache_fsm!=IDLE)|miss, 
        {working_addr, working_target, working_type, working_btb_vld, working_bimodal_prediction, working_btb_index, btb_way
    }, working_valid, icache_busy_o, {icache_ppc_i, icache_btb_target_i, icache_btb_btype_i, icache_btb_vld_i, 
    icache_btb_bm_pred_i,icache_btb_index_i, icache_btb_way_i}, icache_vld_i
    );
    reg [19:0] tags0 [0:31]; reg [19:0] tags1 [0:31];// from addr[31:0], addr[31:12] is extracted, and addr[11:7] used for index, addr[6:0] is offset
    reg valid0 [0:31];reg valid1 [0:31]; reg rr = 0;
    initial begin
        for (integer x = 0; x < 32; x++) begin
            tags0[x] = 0;tags1[x] = 0;
        end
        for (integer x = 0; x < 32; x++) begin
            valid0[x] = 0;valid1[x] = 0;
        end
    end
    assign flush_resp_o = cache_fsm==IDLE;
    assign icache_d_ready = 1'b1;
    reg [4:0] counter = 0;
    /* verilator lint_off UNUSEDSIGNAL */
    wire [31:0] used_address;
    generate if (ENABLE_C_EXTENSION) begin : __if_IALIGN2
        assign used_address = {working_addr, 1'b0};
    end else begin : __if_IALIGN4
        assign used_address = {working_addr,2'b00};
    end endgenerate
    /* verilator lint_on UNUSEDSIGNAL */
    wire [1:0] present = {tags1[used_address[11:7]]==used_address[31:12] && valid1[used_address[11:7]], tags0[used_address[11:7]]==used_address[31:12] && valid0[used_address[11:7]]};
    assign req_not_found = working_valid&!(|present);
    wire [8:0] ram_addr;
    wire [63:0] ram_data;
    assign dec_instruction_o = ram_data; // When busy_i true, data must be held stable.
    generate if (ENABLE_C_EXTENSION) begin : ___if_IALIGN2
        assign ram_addr = working_addr[10:2];
    end else begin : ___if_IALIGN4
        assign ram_addr = working_addr[9:1];
    end endgenerate
    wire [1:0] valids = {valid1[used_address[11:7]],valid0[used_address[11:7]]};
    reg random_sample = 0;
    wire replacement = &valids ? random_sample : ~valids[1];
    wire rd_en = (cache_fsm==IDLE && !dec_busy_i);
    wire wr_en = cache_fsm==MISS_RESP && icache_d_ready && icache_d_valid&&counter[0];
    wire [9:0] wr_addr;
    reg [31:0] buffer;
    assign wr_addr = {replacement, used_address[11:7] , counter[4:1]};
    braminst sram0 (
        core_clock_i, rd_en, {!present[0], ram_addr}, ram_data, wr_en, wr_addr, {icache_d_data,buffer}
    );
    reg block = 0;
    initial dec_vld_o = 0;
    localparam PMP_ADDR_START = ENABLE_C_EXTENSION==1 ? 6 : 5;
    assign i_addr = working_addr[PC_BITS-1:PMP_ADDR_START];
    always_ff @(posedge core_clock_i) begin
        rr <= ~rr;
        case (cache_fsm)
            IDLE: begin
                if (core_flush_i) begin
                    block <= 0;
                    dec_vld_o <= 0;
                end else if (cache_flush_i) begin
                    cache_fsm <= CFLUSH;
                    dec_vld_o <= 0;
                end else if (block&!dec_busy_i) begin
                    dec_vld_o <= 0;
                end else if (!dec_busy_i) begin
                    if (((!req_not_found|working_addr[PC_BITS-1]|i_kill)&working_valid)) begin
                        dec_vpc_o <= working_addr;
                        dec_excp_code_o <= 1;
                        dec_excp_vld_o <= working_addr[PC_BITS-1]|i_kill;
                        dec_btb_index_o <= working_btb_index;
                        dec_btb_btype_o <= working_type;
                        dec_btb_bm_pred_o <= working_bimodal_prediction;
                        dec_btb_target_o <= working_target;
                        dec_btb_vld_o <= working_btb_vld;
                        dec_btb_way_o <= btb_way;
                        dec_vld_o <= 1;
                    end else if (req_not_found&!working_addr[PC_BITS-1]&!i_kill&working_valid) begin
                        random_sample <= rr;
                        cache_fsm <= MISS_REQ;
                        dec_vld_o <= 0;
                    end else if (!working_valid) begin
                        dec_vld_o <= 0;
                    end
                end
            end 
            MISS_REQ: begin
                icache_a_address <= {used_address[31:7], 7'h00};
                icache_a_corrupt <= 1'b0;
                icache_a_data <= 32'h00000000;
                icache_a_mask <= 4'd0;
                icache_a_opcode <= 3'd4;
                icache_a_param <= 3'd0;
                icache_a_size <= 4'd7; // 128 byte cache lines
                icache_a_valid <= 1'b1;
                cache_fsm <= MISS_RESP;
            end
            MISS_RESP: begin
                icache_a_valid <= icache_a_ready ? 0 : icache_a_valid;
                buffer <= icache_d_data;
                if (icache_d_ready&icache_d_valid) begin
                    if (counter==5'b11111) begin
                        counter <= 5'b00000;
                        cache_fsm <= IDLE;
                        tags0[ used_address[11:7]] <= !replacement ? used_address[31:12] : tags0[used_address[11:7]];
                        valid0[used_address[11:7]] <= !replacement ? 1'b1 : valid0[used_address[11:7]];
                        tags1[ used_address[11:7]] <= replacement ? used_address[31:12] : tags1[used_address[11:7]];
                        valid1[used_address[11:7]] <= replacement ? 1'b1 : valid1[used_address[11:7]];
                    end else begin
                        counter <= counter + 1'b1;
                    end
                end
            end
            CFLUSH: begin
                valid0[counter] <= 1'b0;valid1[counter] <= 1'b0;
                if (counter == 5'b11111) begin
                    cache_fsm <= IDLE;
                    counter <= 0;
                    block <= 1;
                end else begin
                    cache_fsm <= CFLUSH;
                    counter <= counter + 1'b1;
                end
            end
        endcase
    end
endmodule
