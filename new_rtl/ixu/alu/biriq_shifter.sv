
/*
op_i == 5'b00000: sll
op_i == 5'b00001: slr
op_i == 5'b00010: rol
op_i == 5'b00011: ror
op_i == 5'b00101: sra
op_i == 5'b01000: bclr
op_i == 5'b01011: bext
op_i == 5'b11000: binv
op_i == 5'b11010: bset
Everything else is undefined
*/

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

