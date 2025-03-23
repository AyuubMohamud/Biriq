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
/*

op == 4'b0000: add
op == 4'b0001: sh1add
op == 4'b0010: sh2add
op == 4'b0011: sh3add
op == 4'b0100: sub
op == 4'b0101:
op == 4'b1000: sext.b
op == 4'b1001: sext.h
op == 4'b1010: zext.h
op == 4'b1011: Undefined
*/
module biriq_adder #(
    parameter C_HAS_ZBA_EXTENSION = 0,
    parameter C_HAS_ZBB_EXTENSION = 0
) (
    input  wire logic [31:0] a_i,   //! rs1
    input  wire logic [31:0] b_i,   //! rs2 or imm
    // verilator lint_off UNUSED
    input  wire logic [ 3:0] op_i,  //! operation to be performed
    // verilator lint_on UNUSED
    output wire logic [31:0] c_o    //! result
);
  wire [31:0] add_res;  //! result of add
  // verilator lint_off UNUSED
  wire [31:0] ext_res;  //! result of extension
  // verilator lint_on UNUSED
  wire [31:0] sh_res;  //! result of pre-shift
  generate
    if (C_HAS_ZBB_EXTENSION) begin : g_zbb
      assign ext_res = op_i[1:0] == 2'b00 ? {{24{a_i[7]}}, a_i[7:0]} : op_i[1:0] == 2'b01 ? {{16{a_i[15]}}, a_i[15:0]} : op_i[1:0] == 2'b10 ? {16'h0000, a_i[15:0]} : 32'h00000000;
    end else begin : g_nzbb
      assign ext_res = 32'd0;
    end
  endgenerate
  generate
    if (C_HAS_ZBA_EXTENSION) begin : g_zba
      assign sh_res = a_i << op_i[1:0];
    end else begin : g_nzba
      assign sh_res = a_i;
    end
  endgenerate
  assign add_res = op_i[2] ? sh_res - b_i : sh_res + b_i;
  generate
    if (C_HAS_ZBB_EXTENSION) begin : g_zbb_res
      assign c_o = op_i[3] == 1'b0 ? add_res : ext_res;
    end else begin : g_nzbb_res
      assign c_o = add_res;
    end
  endgenerate
endmodule
