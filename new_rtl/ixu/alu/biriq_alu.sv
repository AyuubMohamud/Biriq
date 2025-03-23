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
1-clk ALU
*/

module biriq_alu #(
    parameter C_HAS_ZBA_EXTENSION   = 1,
    parameter C_HAS_ZBB_EXTENSION   = 1,
    parameter C_HAS_ZBS_EXTENSION   = 1,
    parameter C_HAS_CZERO_EXTENSION = 1
) (
    input  wire logic [31:0] a_i,
    input  wire logic [31:0] b_i,
    input  wire logic [ 6:0] op_i,
    output wire logic [31:0] result_o,
    output wire logic [31:0] adder_result_o,
    output wire logic        mts_o,
    output wire logic        mtu_o,
    output wire logic        eq_o
);

  wire [31:0] adder_result;
  wire [31:0] shifter_result;
  wire [31:0] gates_result;
  wire [31:0] branch_result;

  biriq_adder #(
      .C_HAS_ZBA_EXTENSION(C_HAS_ZBA_EXTENSION),
      .C_HAS_ZBB_EXTENSION(C_HAS_ZBB_EXTENSION)
  ) adder_inst (
      .a_i (a_i),
      .b_i (b_i),
      .op_i(op_i[3:0]),
      .c_o (adder_result)
  );

  biriq_shifter #(
      .C_HAS_ZBB_EXTENSION(C_HAS_ZBB_EXTENSION),
      .C_HAS_ZBS_EXTENSION(C_HAS_ZBS_EXTENSION)
  ) shifter_inst (
      .a_i (a_i),
      .b_i (b_i),
      .op_i(op_i[4:0]),
      .c_o (shifter_result)
  );

  biriq_branch #(
      .C_HAS_ZBB_EXTENSION  (C_HAS_ZBB_EXTENSION),
      .C_HAS_CZERO_EXTENSION(C_HAS_CZERO_EXTENSION)
  ) branch_inst (
      .a_i  (a_i),
      .b_i  (b_i),
      .op_i (op_i[2:0]),
      .mts_o(mts_o),
      .mtu_o(mtu_o),
      .eq_o (eq_o),
      .c_o  (branch_result)
  );

  biriq_gates #(
      .C_HAS_ZBB_EXTENSION(C_HAS_ZBB_EXTENSION)
  ) gates_inst (
      .a_i (a_i),
      .b_i (b_i),
      .op_i(op_i[3:0]),
      .c_o (gates_result)
  );

  assign result_o = op_i[6:5] == 2'b00 ? adder_result :
                  op_i[6:5] == 2'b01 ? shifter_result :
                  op_i[6:5] == 2'b10 ? branch_result : 
                  gates_result;
  assign adder_result_o = adder_result;
endmodule
