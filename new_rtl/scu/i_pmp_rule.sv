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
module i_pmp_rule #(
    parameter ENABLE_SMEPMP = 1
) (
    input   wire logic          m_mode,
    input   wire logic          mml,
    input   wire logic          lock_r,
    input   wire logic          exec_r,
    input   wire logic          wr_r,
    input   wire logic          rd_r,
    
    output  wire logic          exec_o
);
    generate if (ENABLE_SMEPMP) begin : __if_smepmp
        logic x_a;
        always_comb begin
            x_a = exec_r;
            if (mml) begin
                case ({lock_r, rd_r, wr_r, exec_r})
                    4'd0:   {x_a} = 1'b0;
                    4'd1:   {x_a} = m_mode ? 1'b0 : 1'b1;
                    4'd2:   {x_a} = m_mode ? 1'b0 : 1'b0;
                    4'd3:   {x_a} = 1'b0;
                    4'd4:   {x_a} = m_mode ? 1'b0 : 1'b0;
                    4'd5:   {x_a} = m_mode ? 1'b0 : 1'b1;
                    4'd6:   {x_a} = m_mode ? 1'b0 : 1'b0;
                    4'd7:   {x_a} = m_mode ? 1'b0 : 1'b1;
                    4'd8:   {x_a} = 1'b0;
                    4'd9:   {x_a} = m_mode ? 1'b1 : 1'b0;
                    4'd10:  {x_a} = 1'b1;
                    4'd11:  {x_a} = m_mode ? 1'b1 : 1'b1;
                    4'd12:  {x_a} = m_mode ? 1'b0 : 1'b0;
                    4'd13:  {x_a} = m_mode ? 1'b1 : 1'b0;
                    4'd14:  {x_a} = 1'b0;
                    4'd15:  {x_a} = 1'b0;
                endcase
            end
        end
        assign exec_o = x_a;
    end else begin : __no_smepmp
        assign exec_o = exec_r;
    end endgenerate
endmodule
