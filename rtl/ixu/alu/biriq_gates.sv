/* verilator lint_off SELRANGE*/
// SPDX-FileCopyrightText: 2024 Ayuub Mohamud <ayuub.mohamud@outlook.com>
// SPDX-License-Identifier: CERN-OHL-W-2.0

//  -----------------------------------------------------------------------------------------
//  | Copyright (c_o) Ayuub Mohamud 2024.                                                     |
//  |                                                                                       |
//  | This source describes Open Hardware (RTL) and is licensed under the CERN-OHL-W v2.    |
//  |                                                                                       |
//  | You may redistribute and modify this source and make products using it under          |
//  | the terms of the CERN-OHL-W v2 (https://ohwr.org/cern_ohl_w_v2.txt).                  |
//  |                                                                                       |
//  | This source is distributed WITHOUT ANY EXPRESS OR IMPLIED WARRANTY,                   |
//  | INCLUDING OF MERCHANTABILITY, SATISFACTORY QUALITY AND FITNESS FOR a_i                  |
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
op_i = 4'b0000: and
op_i = 4'b0001: orr
op_i = 4'b0010: xor
op_i = 4'b0011: orc.b
op_i = 4'b0100: andn
op_i = 4'b0101: orn
op_i = 4'b0110: xnor
op_i = 4'b0111: UNDEFINED
op_i = 4'b1000: ctz
op_i = 4'b1001: undefined
op_i = 4'b1010: rev8
op_i = 4'b1011: cpop
op_i = 4'b1100: clz
op_i >= 4'b1101: UNDEFINED

*/
module biriq_gates #(
    parameter C_HAS_ZBB_EXTENSION = 0
) (
    input  wire logic [31:0] a_i,   //! rs1
    /*verilator lint_off UNUSEDSIGNAL*/
    input  wire logic [31:0] b_i,   //! rs2 or imm
    input  wire logic [ 3:0] op_i,  //! operation to be performed
    output wire logic [31:0] c_o    //! result
);
  logic [31:0] logic_gate_res;  //! Logic gate result
  wire  [31:0] operand_2;  //! not b_i or regular b_i
  wire  [31:0] ct_operand;  //! Bit reversed version for ctz or clz
  logic [ 5:0] res;  //! ctz/clz result
  wire  [31:0] byte_rev_res;  //! Byte reverse
  logic [31:0] bitmanip_res;  //! Final result for clz/ctz, brev8 and rev8
  wire [3:0] res_0, res_1, res_2, res_3;
  wire [4:0] res_0_1, res_1_1;
  wire [5:0] cpop_result;
  /*verilator lint_on UNUSEDSIGNAL*/
  assign operand_2 = op_i[2] ? ~b_i : b_i;
  generate
    if (C_HAS_ZBB_EXTENSION) begin : g_zbb
      always_comb begin
        case (op_i[1:0])
          2'b00: logic_gate_res = a_i & operand_2;
          2'b01: logic_gate_res = a_i | operand_2;
          2'b10: logic_gate_res = a_i ^ operand_2;
          2'b11:
          logic_gate_res = {
            {8{|a_i[31:24]}}, {8{|a_i[23:16]}}, {8{|a_i[15:8]}}, {8{|a_i[7:0]}}
          };  //! This is orc.b
        endcase
      end
    end else begin : g_nzbb
      always_comb begin
        case (op_i[1:0])
          2'b00: logic_gate_res = a_i & operand_2;
          2'b01: logic_gate_res = a_i | operand_2;
          2'b10: logic_gate_res = a_i ^ operand_2;
          2'b11: logic_gate_res = 'x;
        endcase
      end
    end
  endgenerate
  generate
    if (C_HAS_ZBB_EXTENSION) begin : g_zbb_logic
      for (genvar i = 0; i < 32; i++) begin : _clz
        assign ct_operand[i] = !op_i[2] ? a_i[i] : a_i[31-i];
      end

      always_comb begin
        casez (ct_operand)
          32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz1: res = 0;
          32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz10: res = 1;
          32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzz100: res = 2;
          32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzz1000: res = 3;
          32'bzzzzzzzzzzzzzzzzzzzzzzzzzzz10000: res = 4;
          32'bzzzzzzzzzzzzzzzzzzzzzzzzzz100000: res = 5;
          32'bzzzzzzzzzzzzzzzzzzzzzzzzz1000000: res = 6;
          32'bzzzzzzzzzzzzzzzzzzzzzzzz10000000: res = 7;
          32'bzzzzzzzzzzzzzzzzzzzzzzz100000000: res = 8;
          32'bzzzzzzzzzzzzzzzzzzzzzz1000000000: res = 9;
          32'bzzzzzzzzzzzzzzzzzzzzz10000000000: res = 10;
          32'bzzzzzzzzzzzzzzzzzzzz100000000000: res = 11;
          32'bzzzzzzzzzzzzzzzzzzz1000000000000: res = 12;
          32'bzzzzzzzzzzzzzzzzzz10000000000000: res = 13;
          32'bzzzzzzzzzzzzzzzzz100000000000000: res = 14;
          32'bzzzzzzzzzzzzzzzz1000000000000000: res = 15;
          32'bzzzzzzzzzzzzzzz10000000000000000: res = 16;
          32'bzzzzzzzzzzzzzz100000000000000000: res = 17;
          32'bzzzzzzzzzzzzz1000000000000000000: res = 18;
          32'bzzzzzzzzzzzz10000000000000000000: res = 19;
          32'bzzzzzzzzzzz100000000000000000000: res = 20;
          32'bzzzzzzzzzz1000000000000000000000: res = 21;
          32'bzzzzzzzzz10000000000000000000000: res = 22;
          32'bzzzzzzzz100000000000000000000000: res = 23;
          32'bzzzzzzz1000000000000000000000000: res = 24;
          32'bzzzzzz10000000000000000000000000: res = 25;
          32'bzzzzz100000000000000000000000000: res = 26;
          32'bzzzz1000000000000000000000000000: res = 27;
          32'bzzz10000000000000000000000000000: res = 28;
          32'bzz100000000000000000000000000000: res = 29;
          32'bz1000000000000000000000000000000: res = 30;
          32'b10000000000000000000000000000000: res = 31;
          default: res = 32;
        endcase
      end

      assign byte_rev_res = {a_i[7:0], a_i[15:8], a_i[23:16], a_i[31:24]};

      biriq_plc8 plc80 (
          a_i[7:0],
          res_0
      );
      biriq_plc8 plc81 (
          a_i[15:8],
          res_1
      );
      biriq_plc8 plc82 (
          a_i[23:16],
          res_2
      );
      biriq_plc8 plc83 (
          a_i[31:24],
          res_3
      );

      assign res_0_1 = res_0 + res_1;

      assign res_1_1 = res_2 + res_3;

      assign cpop_result = res_0_1 + res_1_1;

      always_comb begin
        case (op_i[1:0])
          2'b00: bitmanip_res = {26'h0, res};
          2'b01: bitmanip_res = {26'h0, res};
          2'b10: bitmanip_res = byte_rev_res;
          2'b11: bitmanip_res = {26'h0, cpop_result};
        endcase
      end

      assign c_o = op_i[3] ? bitmanip_res : logic_gate_res;
    end else begin : g_nzbb_res
      assign c_o = logic_gate_res;
    end
  endgenerate
endmodule
/* verilator lint_on SELRANGE*/
