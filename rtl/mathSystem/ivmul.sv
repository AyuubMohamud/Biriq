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
module ivmul (
    input   wire logic [31:0]   a,
    input   wire logic [31:0]   b,
    input   wire logic [2:0]    opc,
    output       logic [31:0]   result
);

    wire [31:0] mul_result_0 = $signed(a[15:0])*$signed(b[15:0]);
    wire [31:0] mul_result_1 = $signed(a[31:16])*$signed(b[31:16]);

    wire [31:0] accumulator = mul_result_0+mul_result_1;

    wire [7:0] uad8_res [0:3];
    uad8 uad8_0 (a[7:0],b[7:0],uad8_res[0]);
    uad8 uad8_1 (a[15:8],b[15:8],uad8_res[1]);
    uad8 uad8_2 (a[23:16],b[23:16],uad8_res[2]);
    uad8 uad8_3 (a[31:24],b[31:24],uad8_res[3]);
    wire [8:0] usad8_res_0[0:1];
    assign usad8_res_0[0] = uad8_res[0]+uad8_res[1];
    assign usad8_res_0[1] = uad8_res[2]+uad8_res[3];

    wire [9:0] usad8_res = usad8_res_0[0]+usad8_res_0[1];

    wire [15:0] usad16_res_0[0:1];
    uad16 uad16_0 (a[15:0],b[15:0],usad16_res_0[0]);
    uad16 uad16_1 (a[31:16],b[31:16],usad16_res_0[1]);

    wire [16:0] usad16_res;
    assign usad16_res = usad16_res_0[0]+usad16_res_0[1];

    wire [7:0] spb [0:3];
    byteselect bs0 (a[31:0],b[1:0],spb[0]);
    byteselect bs1 (a[31:0],b[9:8],spb[1]);
    byteselect bs2 (a[31:0],b[17:16],spb[2]);
    byteselect bs3 (a[31:0],b[25:24],spb[3]);
    always_comb begin
        case (opc)
            3'b000: begin
                result = {mul_result_1[15:0],mul_result_0[15:0]};
            end
            3'b001: begin
                result = {mul_result_1[31:16],mul_result_0[31:16]};
            end
            3'b010: begin
                result = accumulator;
            end
            3'b011: begin
                result = {22'd0, usad8_res};
            end
            3'b100: begin
                result = {a[15:0],b[15:0]};
            end
            3'b101: begin
                result = {15'd0, usad16_res};
            end
            3'b110: begin
                result = {b[31] ? 8'd0 : spb[3], 
                b[23] ? 8'd0 : spb[2],
                b[15] ? 8'd0 : spb[1],
                b[7] ? 8'd0 : spb[0]};
            end
            3'b111: begin
                result = {16'd0, a[7:0],b[7:0]};
            end
        endcase
    end
endmodule
