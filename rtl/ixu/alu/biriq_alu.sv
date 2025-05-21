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
module biriq_branch #(
    parameter C_HAS_ZBB_EXTENSION   = 1,
    parameter C_HAS_CZERO_EXTENSION = 1
) (
    input  wire [31:0] a_i,    //! rs1
    input  wire [31:0] b_i,    //! rs2 or imm
    input  wire [ 2:0] op_i,   //! operation to be performed
    output wire        mts_o,
    output wire        mtu_o,
    output wire        eq_o,
    output wire [31:0] c_o     //! result
);
  wire [31:0] operand_2;
  wire eq;
  wire gt_30;
  logic mts;
  logic mtu;
  wire mt;
  wire slt;
  generate
    if (C_HAS_CZERO_EXTENSION) begin : g_czero
      assign operand_2 = &op_i[2:1] ? 32'd0 : b_i;
    end else begin : g_nczero
      assign operand_2 = b_i;
    end
  endgenerate

  always_comb begin
    case ({
      a_i[31], b_i[31], gt_30
    })
      3'b000: begin
        mts = 0;
        mtu = 0;
      end
      3'b001: begin
        mts = 1;
        mtu = 1;
      end
      3'b010: begin
        mts = 1;
        mtu = 0;
      end
      3'b011: begin
        mts = 1;
        mtu = 0;
      end
      3'b100: begin
        mts = 0;
        mtu = 1;
      end
      3'b101: begin
        mts = 0;
        mtu = 1;
      end
      3'b110: begin
        mts = 0;
        mtu = 0;
      end
      3'b111: begin
        mts = 1;
        mtu = 1;
      end
    endcase
  end


  assign mt = op_i[2] ? mts : mtu;
  assign eq = a_i == operand_2;
  assign gt_30 = a_i[30:0] > b_i[30:0];
  assign slt = {op_i[1:0]} == 2'b10 ? {!(mts | eq)} : {!(mtu | eq)};

  generate
    if (C_HAS_ZBB_EXTENSION && C_HAS_CZERO_EXTENSION) begin : g_zbb_and_czero
      assign c_o = {op_i[2:1]}==2'b11 ? op_i[0]^eq ? a_i : 0 : {op_i[1:0]} == 2'b00 ? mt ? a_i : operand_2 : {op_i[1:0]} == 2'b01 ? !mt ? a_i : operand_2 : {31'd0, slt};
    end else if (C_HAS_ZBB_EXTENSION && !C_HAS_CZERO_EXTENSION) begin : g_zbb_and_nczero
      assign c_o = {op_i[1:0]} == 2'b00 ? mt ? a_i : operand_2 : {op_i[1:0]} == 2'b01 ? !mt ? a_i : operand_2 : {31'd0, slt};
    end else if (!C_HAS_ZBB_EXTENSION && C_HAS_CZERO_EXTENSION) begin : g_nzbb_and_czero
      assign c_o = {op_i[2:1]} == 2'b11 ? op_i[0] ^ eq ? a_i : 0 : {31'd0, slt};
    end else begin : g_nzbb_and_nczero
      assign c_o = {31'd0, slt};
    end
  endgenerate

  assign mts_o = mts;
  assign mtu_o = mtu;
  assign eq_o  = eq;
endmodule
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
  logic [5:0] cpop_result;
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

      always_comb begin
        cpop_result = 0;
        for (integer i = 0; i < 32; i++) begin
          /* verilator lint_off WIDTHEXPAND */
          cpop_result += a_i[i];
          /* verilator lint_on WIDTHEXPAND */
        end
      end

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


module biriq_shifter #(
    parameter C_HAS_ZBB_EXTENSION = 0,
    parameter C_HAS_ZBS_EXTENSION = 0
) (
    input  wire [31:0] a_i,   //! rs1
    /* verilator lint_off UNUSED*/
    input  wire [31:0] b_i,   //! rs2 or imm
    input  wire [ 4:0] op_i,  //! operation to be performed
    /* verilator lint_on UNUSED*/
    output wire [31:0] c_o    //! result
);

  // shifter, default is shift left, to shift right it is op_i[0] = 1
  wire [31:0] shift_res;
  wire [31:0] operand_1;
  wire [ 4:0] shamt;
  wire [31:0] shift_operand1, shift_stage1, shift_res_stage1, shift_stage2, shift_res_stage2, shift_stage3, shift_res_stage3, shift_stage4, shift_res_stage4, shift_stage5, shift_res_stage5;

  generate
    if (C_HAS_ZBS_EXTENSION) begin : g_one
      assign operand_1 = op_i[3] & !op_i[0] ? 32'b1 : a_i;
    end else begin : g_none
      assign operand_1 = a_i;
    end
  endgenerate

  assign shamt = b_i[4:0];

  for (genvar i = 0; i < 32; i++) begin : g_rev
    assign shift_operand1[i] = !op_i[0] ? operand_1[31-i] : operand_1[i];
  end

  generate
    if (C_HAS_ZBB_EXTENSION) begin : g_gen_shift_w_zbb
      assign shift_stage1[31] = op_i[1] & !op_i[3] ? shift_operand1[0] : (!op_i[3] & op_i[2]) ? a_i[31] : 1'b0;
      assign shift_stage1[30:0] = shift_operand1[31:1];
      assign shift_res_stage1 = shamt[0] ? shift_stage1 : shift_operand1;
      assign shift_stage2[31:30] = op_i[1] & !op_i[3] ? shift_res_stage1[1:0] :  (!op_i[3] & op_i[2]) ? {{2{a_i[31]}}} : 2'b00;
      assign shift_stage2[29:0] = shift_res_stage1[31:2];
      assign shift_res_stage2 = shamt[1] ? shift_stage2 : shift_res_stage1;
      assign shift_stage3[31:28] = op_i[1] & !op_i[3] ? shift_res_stage2[3:0] : (!op_i[3] & op_i[2]) ? {{4{a_i[31]}}} : 4'b00;
      assign shift_stage3[27:0] = shift_res_stage2[31:4];
      assign shift_res_stage3 = shamt[2] ? shift_stage3 : shift_res_stage2;
      assign shift_stage4[31:24] = op_i[1] & !op_i[3] ? shift_res_stage3[7:0] : (!op_i[3] & op_i[2]) ? {{8{a_i[31]}}} : 8'b00;
      assign shift_stage4[23:0] = shift_res_stage3[31:8];
      assign shift_res_stage4 = shamt[3] ? shift_stage4 : shift_res_stage3;
      assign shift_stage5[31:16] = op_i[1] & !op_i[3] ? shift_res_stage4[15:0] : (!op_i[3] & op_i[2]) ? {{16{a_i[31]}}} : 16'b00;
      assign shift_stage5[15:0] = shift_res_stage4[31:16];
      assign shift_res_stage5 = shamt[4] ? shift_stage5 : shift_res_stage4;
    end else begin : g_gen_shift_wo_zbb
      assign shift_stage1[31] = (!op_i[3] & op_i[2]) ? a_i[31] : 1'b0;
      assign shift_stage1[30:0] = shift_operand1[31:1];
      assign shift_res_stage1 = shamt[0] ? shift_stage1 : shift_operand1;
      assign shift_stage2[31:30] = (!op_i[3] & op_i[2]) ? {{2{a_i[31]}}} : 2'b00;
      assign shift_stage2[29:0] = shift_res_stage1[31:2];
      assign shift_res_stage2 = shamt[1] ? shift_stage2 : shift_res_stage1;
      assign shift_stage3[31:28] = (!op_i[3] & op_i[2]) ? {{4{a_i[31]}}} : 4'b00;
      assign shift_stage3[27:0] = shift_res_stage2[31:4];
      assign shift_res_stage3 = shamt[2] ? shift_stage3 : shift_res_stage2;
      assign shift_stage4[31:24] = (!op_i[3] & op_i[2]) ? {{8{a_i[31]}}} : 8'b00;
      assign shift_stage4[23:0] = shift_res_stage3[31:8];
      assign shift_res_stage4 = shamt[3] ? shift_stage4 : shift_res_stage3;
      assign shift_stage5[31:16] = (!op_i[3] & op_i[2]) ? {{16{a_i[31]}}} : 16'b00;
      assign shift_stage5[15:0] = shift_res_stage4[31:16];
      assign shift_res_stage5 = shamt[4] ? shift_stage5 : shift_res_stage4;
    end
  endgenerate

  for (genvar i = 0; i < 32; i++) begin : g_rev_b
    assign shift_res[i] = !op_i[0] ? shift_res_stage5[31-i] : shift_res_stage5[i];
  end

  // postgate
  generate
    if (C_HAS_ZBS_EXTENSION) begin : g_pg
      logic [31:0] postgate_res;
      always_comb begin
        case ({
          op_i[4], op_i[1]
        })
          2'b00: postgate_res = a_i & ~shift_res;
          2'b01: postgate_res = shift_res & 1;
          2'b10: postgate_res = a_i ^ shift_res;
          2'b11: postgate_res = a_i | shift_res;
        endcase
      end

      assign c_o = op_i[3] ? postgate_res : shift_res;
    end else begin : g_npg
      assign c_o = shift_res;
    end
  endgenerate

endmodule

