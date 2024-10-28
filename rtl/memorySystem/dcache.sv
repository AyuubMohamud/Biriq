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
module dcache #(parameter ACP_RS = 1) (
    input   wire logic                          cpu_clock_i,

    // Cache interface
    output  wire logic                          cache_done,
    input   wire logic [29:0]                   store_address_i,
    input   wire logic [31:0]                   store_data_i,
    input   wire logic [3:0]                    store_bm_i,
    input   wire logic                          store_valid_i,
    // cache request
    input   wire logic                          dc_req,
    input   wire logic [31:0]                   dc_addr,
    input   wire logic [1:0]                    dc_op,
    input   wire logic                          dc_uncached,
    output       logic [31:0]                   dc_data_o,
    output  wire logic                          dc_cmp,
    // sram
    input   wire logic                          bram_rd_en,
    input   wire logic [9:0]                    bram_rd_addr,
    output  wire logic [63:0]                   bram_rd_data,
    
    // TileLink Bus Master Uncached Heavyweight
    output       logic [2:0]                    dcache_a_opcode,
    output       logic [2:0]                    dcache_a_param,
    output       logic [3:0]                    dcache_a_size,
    output       logic [31:0]                   dcache_a_address,
    output       logic [3:0]                    dcache_a_mask,
    output       logic [31:0]                   dcache_a_data,
    output       logic                          dcache_a_corrupt,
    output       logic                          dcache_a_valid,
    input   wire logic                          dcache_a_ready, 
    /* verilator lint_off UNUSEDSIGNAL */
    input   wire logic [2:0]                    dcache_d_opcode,
    input   wire logic [1:0]                    dcache_d_param,
    input   wire logic [3:0]                    dcache_d_size,
    input   wire logic                          dcache_d_denied,
    /* verilator lint_on UNUSEDSIGNAL */
    input   wire logic [31:0]                   dcache_d_data,
    /* verilator lint_off UNUSEDSIGNAL */
    input   wire logic                          dcache_d_corrupt,
    /* verilator lint_on UNUSEDSIGNAL */
    input   wire logic                          dcache_d_valid,
    output  wire logic                          dcache_d_ready,

    // TileLink Bus Slave Uncached Lightweight to keep coherent
    input   wire logic [2:0]                    acp_a_opcode,
    /* verilator lint_off UNUSEDSIGNAL */
    input   wire logic [2:0]                    acp_a_param,
    /* verilator lint_on UNUSEDSIGNAL */
    input   wire logic [3:0]                    acp_a_size,
    input   wire logic [ACP_RS-1:0]             acp_a_source,
    input   wire logic [31:0]                   acp_a_address,
    input   wire logic [3:0]                    acp_a_mask,
    input   wire logic [31:0]                   acp_a_data,
    input   wire logic                          acp_a_valid,
    output  wire logic                          acp_a_ready, 

    output       logic [2:0]                    acp_d_opcode,
    /* verilator lint_off UNUSEDSIGNAL */
    output       logic [1:0]                    acp_d_param,
    /* verilator lint_on UNUSEDSIGNAL */
    output       logic [3:0]                    acp_d_size,
    output       logic [ACP_RS-1:0]             acp_d_source,
    /* verilator lint_on UNUSEDSIGNAL */
    output       logic                          acp_d_denied,
    /* verilator lint_off UNUSEDSIGNAL */
    output       logic [31:0]                   acp_d_data,
    /* verilator lint_on UNUSEDSIGNAL */
    output       logic                          acp_d_corrupt,
    /* verilator lint_off UNUSEDSIGNAL */
    output       logic                          acp_d_valid,
    input   wire logic                          acp_d_ready,

    // cache tags
    input   wire logic [23:0]                   load_cache_set_i,
    output  wire logic                          load_set_valid_o,
    output  wire logic                          load_set_o
);
    reg [18:0] tags0 [0:31]; reg [18:0] tags1 [0:31];// from addr[31:0], addr[31:12] is extracted, and addr[12:7] used for index, addr[6:0] is offset
    reg valid0 [0:31];reg valid1 [0:31]; reg [1:0] rr= 2'b01;
    wire [1:0] replacement_bitvec; wire replacement_enc;
    initial begin
        for (integer x = 0; x < 32; x++) begin
            tags0[x] = 0;tags1[x] = 0;
        end
        for (integer x = 0; x < 32; x++) begin
            valid0[x] = 0;valid1[x] = 0;
        end
    end
    wire [ACP_RS-1:0] working_acp_source;
    wire [3:0] working_acp_size;
    wire [31:0] working_acp_data;
    wire [3:0] working_acp_mask;
    wire [2:0] working_acp_opcode;
    wire [31:0] working_acp_address;
    wire working_acp_valid;
    wire acp_busy;
    localparam IDLE = 3'b000;    reg [2:0] cache_fsm = IDLE;
    skdbf #(ACP_RS+43+32) skidbuffer (cpu_clock_i, 1'b0, cache_fsm!=IDLE, {
        working_acp_source,
        working_acp_size,
        working_acp_data,
        working_acp_mask,
        working_acp_opcode,
        working_acp_address
    }, working_acp_valid, acp_busy, {
        acp_a_source, acp_a_size, acp_a_data, acp_a_mask, acp_a_opcode, acp_a_address
    }, acp_a_valid);
    assign acp_a_ready = ~acp_busy;
    reg [3:0] size = 0; reg [ACP_RS-1:0] source = 0;

    localparam LOAD_CMP = 3'b010;
    localparam STORE_CMP = 3'b011;
    localparam VICTIM = 3'b001;
    localparam SERVICE_COHERENT = 3'b100;

    reg [4:0] counter = 0; 
    wire [7:0] wr_en; wire [9:0] wr_addr; wire [63:0] wr_data; 
    wire [1:0] match_tags; wire match_line; wire [1:0] match_vld; wire [1:0] match;
    assign match_tags = {tags1[dcache_a_address[11:7]]==dcache_a_address[30:12], tags0[dcache_a_address[11:7]]==dcache_a_address[30:12]};
    assign match_vld = {valid1[dcache_a_address[11:7]], valid0[dcache_a_address[11:7]]};
    assign match = match_tags & match_vld;
    
    assign match_line = match[1];
    reg [31:0] buffer;
    dbraminst dsram (cpu_clock_i, bram_rd_en, bram_rd_addr, bram_rd_data, wr_en, wr_addr, wr_data);
    wire [3:0] wr_en32 = {((|match)&(cache_fsm==STORE_CMP)&store_bm_i[3]),
    ((|match)&(cache_fsm==STORE_CMP)&store_bm_i[2]), ((|match)&(cache_fsm==STORE_CMP)&store_bm_i[1]), 
    ((|match)&(cache_fsm==STORE_CMP)&store_bm_i[0])};
    wire cache_fill = (cache_fsm==LOAD_CMP)&(dcache_d_valid)&(!dc_addr[31]);
    wire [7:0] wr_en64 = store_address_i[0] ? {wr_en32, 4'h0} : {4'h0, wr_en32};
    assign wr_en = {8{(cache_fill&counter[0]&dcache_d_valid)}}|wr_en64;
    wire [1:0] ld_vld = {valid1[load_cache_set_i[4:0]], valid0[load_cache_set_i[4:0]]};
    wire [1:0] ld_mtch = {tags1[load_cache_set_i[4:0]]==load_cache_set_i[23:5], tags0[load_cache_set_i[4:0]]==load_cache_set_i[23:5]} &
    ld_vld;
    assign load_set_o = ld_mtch[1];
    assign load_set_valid_o = |ld_mtch;
    assign replacement_bitvec = &match_vld ? rr : match_vld==2'b00 ? 2'b01 : match_vld==2'b01 ? 2'b10 : 2'b01;
    assign replacement_enc = replacement_bitvec[1];
    assign wr_addr = cache_fsm==LOAD_CMP ? {replacement_enc, dc_addr[11:7], counter[4:1]} : {match_line, store_address_i[9:1]};
    assign wr_data = cache_fsm==LOAD_CMP ? {dcache_d_data, buffer} : {store_data_i,store_data_i};
    assign dc_cmp = ((dc_addr[31]|dc_uncached)&(cache_fsm==LOAD_CMP)&(dcache_d_valid))|((cache_fsm==LOAD_CMP)&(counter==5'd31)&dcache_d_valid&!dc_addr[31]&!dc_uncached);
    assign cache_done = cache_fsm==STORE_CMP && dcache_d_valid; assign dcache_d_ready = 1'b1;
    logic [1:0] recover_low_order; logic [1:0] op; logic [31:0] recovered_data;
    initial dcache_a_valid = 0;
    always_comb begin
        case (store_bm_i[3:0])
            4'b0001: begin
                recover_low_order = 2'b00;
                op = 2'b00;
                recovered_data = store_data_i;
            end
            4'b0010: begin
                recover_low_order = 2'b01;
                op = 2'b00;
                recovered_data = {24'h000000, store_data_i[15:8]};
            end
            4'b0011: begin
                recover_low_order = 2'b00;
                op = 2'b01; recovered_data = store_data_i;
            end
            4'b0100: begin
                recover_low_order = 2'b10;
                op = 2'b00; recovered_data = {24'h000000, store_data_i[23:16]};
            end
            4'b1100: begin
                recover_low_order = 2'b10;
                op = 2'b01; recovered_data = {16'h0000, store_data_i[31:16]};
            end
            4'b1000: begin
                recover_low_order = 2'b11;
                op = 2'b00; recovered_data = {24'h000000, store_data_i[31:24]};
            end
            4'b1111: begin
                recover_low_order = 2'b00;
                op = 2'b10; recovered_data = store_data_i;
            end
            default: begin
                recover_low_order = 0; op = 0; recovered_data = store_data_i;
            end
        endcase
    end
    assign dc_data_o = dcache_d_data;
    always_ff @(posedge cpu_clock_i) begin  
        case (cache_fsm)
            IDLE: begin
                acp_d_valid <= acp_d_ready ? 1'b0 : acp_d_valid;
                rr <= {rr[0],rr[1]};
                if (working_acp_valid) begin
                    cache_fsm <= SERVICE_COHERENT;
                    dcache_a_address <= working_acp_address;
                    dcache_a_opcode <= working_acp_opcode; dcache_a_size <= working_acp_size; dcache_a_valid <= 1;
                    dcache_a_data <= working_acp_data; dcache_a_mask <= working_acp_mask; source <= working_acp_source;
                    size <= working_acp_size;
                end
                else if (store_valid_i) begin
                    cache_fsm <= STORE_CMP;
                    dcache_a_address <= {store_address_i, recover_low_order};
                    dcache_a_opcode <= 3'd0; dcache_a_size <= {2'b00,op}; dcache_a_valid <= 1;
                    dcache_a_data <= recovered_data; dcache_a_mask <= 4'hF;
                end else if (dc_req) begin
                    cache_fsm <= VICTIM;
                    dcache_a_address <= dc_addr[31]|dc_uncached ? dc_addr : {dc_addr[31:7],7'h00}; dcache_a_mask <= 0; dcache_a_param <= 0;
                    dcache_a_corrupt <= 0;
                    dcache_a_opcode <= 3'd4; dcache_a_size <= dc_addr[31]|dc_uncached ? {2'b00,dc_op[1:0]} : 4'd7; 
                end
            end
            VICTIM: begin
                dcache_a_valid <= 1;
                valid0[dc_addr[11:7]] <= replacement_bitvec[0]&!dc_uncached ? 1'b0 : valid0[dc_addr[11:7]];
                valid1[dc_addr[11:7]] <= replacement_bitvec[1]&!dc_uncached ? 1'b0 : valid1[dc_addr[11:7]];
                cache_fsm <= LOAD_CMP;
            end
            LOAD_CMP: begin
                acp_d_valid <= acp_d_ready ? 1'b0 : acp_d_valid;
                dcache_a_valid <= dcache_a_ready ? 1'b0 : dcache_a_valid;
                if (dc_uncached&dcache_d_valid) begin
                    cache_fsm <= IDLE;
                end                        
                if (!dc_uncached&dcache_d_valid) begin
                    if (counter==5'd31) begin
                        counter <= 0;
                        cache_fsm <= IDLE;
                        tags0[dc_addr[11:7]] <= replacement_bitvec[0] ? dc_addr[30:12] : tags0[dc_addr[11:7]];
                        tags1[dc_addr[11:7]] <= replacement_bitvec[1] ? dc_addr[30:12] : tags1[dc_addr[11:7]];
                        valid0[dc_addr[11:7]] <= replacement_bitvec[0] ? 1'b1 : valid0[dc_addr[11:7]];
                        valid1[dc_addr[11:7]] <= replacement_bitvec[1] ? 1'b1 : valid1[dc_addr[11:7]];
                    end else begin
                        counter <= counter + 1'b1;
                    end
                    if (!counter[0]) begin
                        buffer <= dcache_d_data;
                    end
                end
            end
            STORE_CMP: begin
                acp_d_valid <= acp_d_ready ? 1'b0 : acp_d_valid;
                rr <= ~rr;
                dcache_a_valid <= dcache_a_ready ? 1'b0 : dcache_a_valid;
                if (dcache_d_valid) begin
                    cache_fsm <= IDLE;
                end
            end
            SERVICE_COHERENT: begin
                dcache_a_valid <= dcache_a_ready ? 1'b0 : dcache_a_valid;
                rr <= ~rr;
                if (dcache_d_valid) begin
                    acp_d_data <= dcache_d_data;
                    acp_d_opcode <= dcache_d_opcode;
                    acp_d_valid <= 1;
                    valid0[dcache_a_address[11:7]] <= match[0] ? 1'b0 : valid0[dcache_a_address[11:7]];
                    valid1[dcache_a_address[11:7]] <= match[1] ? 1'b0 : valid1[dcache_a_address[11:7]];
                    cache_fsm <= IDLE;
                    acp_d_size <= size;
                    acp_d_source <= source;
                end
            end
        endcase
    end
    assign acp_d_corrupt = 0;
    assign acp_d_denied = 0;
    assign acp_d_param = 0;
endmodule
