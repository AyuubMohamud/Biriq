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
module complex_unit (
    input   wire logic              clk_i,
    input   wire logic              flush_i,
    input   wire logic  [2:0]       opcode_i,
    input   wire logic  [31:0]      operand1_i,
    input   wire logic  [31:0]      operand2_i,
    input   wire logic              valid_i,

    output  wire logic              busy_o,
    output       logic  [31:0]      result_o,
    output       logic              wb_valid_o
);
    wire divider_busy;
    wire divider_done;
    wire divider_vld;
    wire divider_dbz;
    wire divider_overflow;
    wire [31:0] quotient;
    wire [31:0] remainder;
    reg busy = 0;
    division divider (clk_i, flush_i, (opcode_i[2])&!busy&valid_i, opcode_i[0], divider_busy, divider_done, divider_vld, divider_dbz, divider_overflow, operand1_i, operand2_i, quotient, remainder);
    wire [31:0] multiplier_result;
    wire multiplier_valid;
    multiplier multiplier (clk_i, flush_i, operand1_i, operand2_i, opcode_i[1:0], (!opcode_i[2])&valid_i&!busy, multiplier_result, multiplier_valid);
    
    assign busy_o = busy|valid_i;
    initial wb_valid_o = 0;
    always_ff @(posedge clk_i) begin
        if (flush_i) begin
            wb_valid_o <= 0;
            busy <= 0;
        end else begin
            case (busy)
            1'b0: begin
                if (valid_i) begin
                    busy <= 1'b1;
                end else begin
                    busy <= 1'b0;
                end
                wb_valid_o <= 1'b0;
            end
            1'b1: begin
                if (divider_done) begin
                    if (divider_dbz) begin
                        result_o <= opcode_i[1] ? operand1_i : 32'hFFFFFFFF;
                    end else if (divider_overflow) begin
                        result_o <= opcode_i[1] ? 32'h00000000 : 32'h80000000;
                    end else begin
                        result_o <= opcode_i[1] ? remainder : quotient;
                    end
                    wb_valid_o <= 1'b1;
                    busy <= 0;
                end
                else if (multiplier_valid) begin
                    result_o <= multiplier_result;
                    wb_valid_o <= 1'b1;
                    busy <= 0;
                end
                else begin
                    wb_valid_o <= 1'b0;
                end
            end
        endcase
        end
    end


endmodule
