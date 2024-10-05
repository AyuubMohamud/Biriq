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
//  | PARTICULAR PURPOSE. Please see the CERN-OHL-S v2 for applicable conditions.           |
//  |                                                                                       |
//  | Source location: https://github.com/AyuubMohamud/Biriq                                |
//  |                                                                                       |
//  | As per CERN-OHL-W v2 section 4, should You produce hardware based on this             |
//  | source, You must where practicable maintain the Source Location visible               |
//  | in the same manner as is done within this source.                                     |
//  |                                                                                       |
//  -----------------------------------------------------------------------------------------
module ivcmper (
    input   wire logic [31:0]   a,
    input   wire logic [31:0]   b,
    input   wire logic [3:0]    op,
    input   wire logic          size,

    output  wire logic [31:0]   result
);
    // operations: max(u), min(u), mseq, msneq, mslt(u), mslte(u), msgt(u)
    wire [3:0] gt_7 = {a[30:24]>b[30:24], a[22:16]>b[22:16], a[14:8]>b[14:8], a[6:0]>b[6:0]};
    wire [3:0] eq8 = {a[31:24]==b[31:24], a[23:16]==b[23:16], a[15:8]==b[15:8], a[7:0]==b[7:0]};
    wire [1:0] eq16 = {&eq8[3:2], &eq8[1:0]};
    wire [1:0] gt_15 = {a[30:16]>b[30:16], a[14:0]>b[14:0]};

    logic mts_16_0;
    logic mtu_16_0;
    always_comb begin
        case ({a[15], b[15], gt_15[0]})
            3'b000: begin
                mts_16_0 = 0; mtu_16_0 = 0;
            end
            3'b001: begin
                mts_16_0 = 1; mtu_16_0 = 1;
            end
            3'b010: begin
                mts_16_0 = 1; mtu_16_0 = 0;
            end
            3'b011: begin
                mts_16_0 = 1; mtu_16_0 = 0;
            end
            3'b100: begin
                mts_16_0 = 0; mtu_16_0 = 1;
            end
            3'b101: begin
                mts_16_0 = 0; mtu_16_0 = 1;
            end
            3'b110: begin
                mts_16_0 = 0; mtu_16_0 = 0;
            end
            3'b111: begin
                mts_16_0 = 1; mtu_16_0 = 1;
            end
        endcase
    end
    logic mts_16_1;
    logic mtu_16_1;
    always_comb begin
        case ({a[31], b[31], gt_15[1]})
            3'b000: begin
                mts_16_1 = 0; mtu_16_1 = 0;
            end
            3'b001: begin
                mts_16_1 = 1; mtu_16_1 = 1;
            end
            3'b010: begin
                mts_16_1 = 1; mtu_16_1 = 0;
            end
            3'b011: begin
                mts_16_1 = 1; mtu_16_1 = 0;
            end
            3'b100: begin
                mts_16_1 = 0; mtu_16_1 = 1;
            end
            3'b101: begin
                mts_16_1 = 0; mtu_16_1 = 1;
            end
            3'b110: begin
                mts_16_1 = 0; mtu_16_1 = 0;
            end
            3'b111: begin
                mts_16_1 = 1; mtu_16_1 = 1;
            end
        endcase
    end
    logic mts_8_0;
    logic mtu_8_0;
    always_comb begin
        case ({a[7], b[7], gt_7[0]})
            3'b000: begin
                mts_8_0 = 0; mtu_8_0 = 0;
            end
            3'b001: begin
                mts_8_0 = 1; mtu_8_0 = 1;
            end
            3'b010: begin
                mts_8_0 = 1; mtu_8_0 = 0;
            end
            3'b011: begin
                mts_8_0 = 1; mtu_8_0 = 0;
            end
            3'b100: begin
                mts_8_0 = 0; mtu_8_0 = 1;
            end
            3'b101: begin
                mts_8_0 = 0; mtu_8_0 = 1;
            end
            3'b110: begin
                mts_8_0 = 0; mtu_8_0 = 0;
            end
            3'b111: begin
                mts_8_0 = 1; mtu_8_0 = 1;
            end
        endcase
    end
    logic mts_8_1;
    logic mtu_8_1;
    always_comb begin
        case ({a[15], b[15], gt_7[1]})
            3'b000: begin
                mts_8_1 = 0; mtu_8_1 = 0;
            end
            3'b001: begin
                mts_8_1 = 1; mtu_8_1 = 1;
            end
            3'b010: begin
                mts_8_1 = 1; mtu_8_1 = 0;
            end
            3'b011: begin
                mts_8_1 = 1; mtu_8_1 = 0;
            end
            3'b100: begin
                mts_8_1 = 0; mtu_8_1 = 1;
            end
            3'b101: begin
                mts_8_1 = 0; mtu_8_1 = 1;
            end
            3'b110: begin
                mts_8_1 = 0; mtu_8_1 = 0;
            end
            3'b111: begin
                mts_8_1 = 1; mtu_8_1 = 1;
            end
        endcase
    end
    logic mts_8_2;
    logic mtu_8_2;
    always_comb begin
        case ({a[23], b[23], gt_7[2]})
            3'b000: begin
                mts_8_2 = 0; mtu_8_2 = 0;
            end
            3'b001: begin
                mts_8_2 = 1; mtu_8_2 = 1;
            end
            3'b010: begin
                mts_8_2 = 1; mtu_8_2 = 0;
            end
            3'b011: begin
                mts_8_2 = 1; mtu_8_2 = 0;
            end
            3'b100: begin
                mts_8_2 = 0; mtu_8_2 = 1;
            end
            3'b101: begin
                mts_8_2 = 0; mtu_8_2 = 1;
            end
            3'b110: begin
                mts_8_2 = 0; mtu_8_2 = 0;
            end
            3'b111: begin
                mts_8_2 = 1; mtu_8_2 = 1;
            end
        endcase
    end
    logic mts_8_3;
    logic mtu_8_3;
    always_comb begin
        case ({a[31], b[31], gt_7[3]})
            3'b000: begin
                mts_8_3 = 0; mtu_8_3 = 0;
            end
            3'b001: begin
                mts_8_3 = 1; mtu_8_3 = 1;
            end
            3'b010: begin
                mts_8_3 = 1; mtu_8_3 = 0;
            end
            3'b011: begin
                mts_8_3 = 1; mtu_8_3 = 0;
            end
            3'b100: begin
                mts_8_3 = 0; mtu_8_3 = 1;
            end
            3'b101: begin
                mts_8_3 = 0; mtu_8_3 = 1;
            end
            3'b110: begin
                mts_8_3 = 0; mtu_8_3 = 0;
            end
            3'b111: begin
                mts_8_3 = 1; mtu_8_3 = 1;
            end
        endcase
    end
    wire [3:0] mt8 = op[3] ? {mts_8_3, mts_8_2, mts_8_1, mts_8_0} : {mtu_8_3, mtu_8_2, mtu_8_1, mtu_8_0};
    wire [1:0] mt16 = op[3] ? {mts_16_1,mts_16_0} : {mtu_16_1, mtu_16_0};
    wire [3:0] lt8 = ~mt8&~eq8;
    wire [1:0] lt16 = ~mt16&~eq16;
    // so we have each byte of our max result
    wire [31:0] max = {(mt16[1]&size)|(mt8[3]&(!size)) ? a[31:24] : b[31:24],
    (mt16[1]&size)|(mt8[2]&(!size)) ? a[23:16] : b[23:16],
    (mt16[0]&size)|(mt8[1]&(!size)) ? a[15:8] : b[15:8],(mt16[0]&size)|(mt8[0]&!size) ? a[7:0] : b[7:0]};
    wire [31:0] min = {(lt16[1]&size)|(lt8[3]&!size) ? a[31:24] : b[31:24],
    (lt16[1]&size)|(lt8[2]&!size) ? a[23:16] : b[23:16],
    (lt16[0]&size)|(lt8[1]&!size) ? a[15:8] : b[15:8],(lt16[0]&size)|(lt8[0]&!size) ? a[7:0] : b[7:0]};
    wire [31:0] meq = size==1'b0 ? {{8{eq8[3]}}, {8{eq8[2]}}, {8{eq8[1]}}, {8{eq8[0]}}} : {{16{eq16[1]}}, {16{eq16[0]}}};
    wire [31:0] mlt = size==1'b0 ? {{8{lt8[3]}}, {8{lt8[2]}}, {8{lt8[1]}}, {8{lt8[0]}}} : {{16{lt16[1]}}, {16{lt16[0]}}};
    wire [31:0] mlte = mlt|meq;
    wire [31:0] mgt = size==1'b0 ? {{8{mt8[3]}}, {8{mt8[2]}}, {8{mt8[1]}}, {8{mt8[0]}}} : {{16{mt16[1]}}, {16{mt16[0]}}};
    wire [31:0] meq_f = op[3] ? ~meq : meq;

    assign result = op[2:0]==3'b000 ? max : op[2:0]==3'b001 ? min : op[2:0]==3'b100 ? meq_f : op[2:0]==3'b101 ? mlt : op[2:0]==3'b110 ? mlte : mgt;
endmodule
