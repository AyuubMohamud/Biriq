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
module d_pmp_rule #(
    parameter ENABLE_SMEPMP = 1
) (
    input   wire logic          m_mode,
    input   wire logic          mml,
    input   wire logic          lock_r,
    input   wire logic          exec_r,
    input   wire logic          wr_r,
    input   wire logic          rd_r,
    
    output  wire logic          rd_o,
    output  wire logic          wr_o
);
    generate if (ENABLE_SMEPMP) begin : __if_smepmp
        logic w_a;
        logic r_a;
        always_comb begin
            w_a = wr_r;
            r_a = rd_r;
            if (mml) begin
                case ({lock_r, rd_r, wr_r, exec_r})
                    4'd0:   {w_a, r_a} = 2'b00;
                    4'd1:   {w_a, r_a} = m_mode ? 2'b00 : 2'b00;
                    4'd2:   {w_a, r_a} = m_mode ? 2'b11 : 2'b01;
                    4'd3:   {w_a, r_a} = 2'b11;
                    4'd4:   {w_a, r_a} = m_mode ? 2'b00 : 2'b01;
                    4'd5:   {w_a, r_a} = m_mode ? 2'b00 : 2'b01;
                    4'd6:   {w_a, r_a} = m_mode ? 2'b00 : 2'b11;
                    4'd7:   {w_a, r_a} = m_mode ? 2'b00 : 2'b11;
                    4'd8:   {w_a, r_a} = 2'b00;
                    4'd9:   {w_a, r_a} = m_mode ? 2'b00 : 2'b00;
                    4'd10:  {w_a, r_a} = 2'b00;
                    4'd11:  {w_a, r_a} = m_mode ? 2'b01 : 2'b00;
                    4'd12:  {w_a, r_a} = m_mode ? 2'b01 : 2'b00;
                    4'd13:  {w_a, r_a} = m_mode ? 2'b01 : 2'b00;
                    4'd14:  {w_a, r_a} = m_mode ? 2'b11 : 2'b00;
                    4'd15:  {w_a, r_a} = 2'b01;
                endcase
            end
        end
        assign rd_o = r_a;
        assign wr_o = w_a;
    end else begin : __no_smepmp
        assign rd_o = rd_r;
        assign wr_o = wr_r;
    end endgenerate
endmodule
