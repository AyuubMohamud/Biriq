module simple_pipe (
    input wire core_clock_i,
    input wire core_reset_i,
    input wire [5:0] simple_rs1_i,
    input wire [5:0] simple_rs2_i,
    input wire [5:0] simple_rob_i,
    input wire simple_vld_i,
    output wire logic [4:0] simple_rob_o,
    // instruction ram
    input wire logic [6:0] simple_opcode_i,
    input wire logic [5:0] simple_ins_type,  // 0 = ALU, 1 = JAL, 2 = JALR, 3 = LUI, 4 - AUIPC
    input wire logic simple_imm_i,
    input wire logic [31:0] simple_immediate_i,
    input wire logic [5:0] simple_dest_i,
    input wire logic [1:0] simple_hint_i,
    input wire logic [29:0] simple_pc_i,
    // Branch info
    input wire logic [1:0] simple_bm_pred_i,
    input wire logic [1:0] simple_btype_i,
    input wire logic simple_btb_vld_i,
    input wire logic [29:0] simple_btb_target_i,
    input wire logic simple_btb_way_i,
    input wire logic simple_btb_idx_i,
    output wire logic [5:0] p0_rs1_o,
    output wire logic [5:0] p0_rs2_o,
    input wire logic [31:0] p0_rs1_data_i,
    input wire logic [31:0] p0_rs2_data_i,
    output wire logic [31:0] simple_ex_fwd_data_o,
    output wire logic [5:0] simple_ex_fwd_dest_o,
    output wire logic simple_ex_fwd_valid_o
);
  reg [31:0] simple_a;
  reg [31:0] simple_b;
  reg [ 6:0] simple_op;
  reg [ 5:0] simple_rob;
  reg [ 5:0] simple_dest;
  reg [31:0] simple_offset;
  reg [29:0] simple_bnch_pc;
  reg        simple_bnch_auipc;
  reg        simple_bnch_call;
  reg        simple_bnch_ret;
  reg        simple_bnch_jal;
  reg        simple_bnch_jalr;
  reg [ 2:0] simple_bnch_bnch_cond;
  reg [ 1:0] simple_bnch_bm_pred;
  reg [ 1:0] simple_bnch_btype;
  reg        simple_bnch_btb_vld;
  reg [29:0] simple_bnch_btb_target;
  reg        simple_bnch_btb_way;
  reg [5:0] simple_ex_rob_id, simple_wb_rob_id;
  reg [5:0] simple_ex_dest, simple_wb_dest;
  reg simple_wr_valid;  // Does it write back?
  reg simple_br_valid;  // Is execute stage executing from branch unit?
  reg simple_ex_valid;  // Is execute stage valid


  wire simple_mts, simple_mtu, simple_eq;
  wire [31:0] simple_alu_result, simple_adder_result, branch_unit_result;
  wire wrongful_nbranch;
  wire wrongful_target;
  wire wrongful_type;
  wire wrongful_bm;

  assign p0_rs1_o = simple_rs1_i;
  assign p0_rs2_o = simple_rs2_i;
  assign simple_ex_fwd_data_o = simple_br_valid ? branch_unit_result : simple_alu_result;
  assign simple_ex_fwd_dest_o = simple_ex_dest;
  assign simple_ex_fwd_valid_o = simple_ex_valid;

  always_ff @(posedge core_clock_i) begin
    simple_a <= simple_ins_type[3] ? 32'd0 : p0_rs1_data_i;
    simple_b <= simple_imm_i | simple_ins_type[3] ? simple_immediate_i : p0_rs2_data_i;
  end

  biriq_alu #(
      .C_HAS_ZBA_EXTENSION  (1'b1),
      .C_HAS_ZBB_EXTENSION  (1'b1),
      .C_HAS_ZBS_EXTENSION  (1'b1),
      .C_HAS_CZERO_EXTENSION(1'b1)
  ) simple_alu (
      .a_i(simple_a),
      .b_i(simple_b),
      .op_i(simple_op),
      .result_o(simple_alu_result),
      .adder_result_o(simple_adder_result),
      .mts_o(simple_mts),
      .mtu_o(simple_mtu),
      .eq_o(simple_eq)
  );

  branchUnit branchUnit_inst (
      .operand_1(simple_a),
      .offset(simple_offset),
      .pc(simple_bnch_pc),
      .auipc(simple_bnch_auipc),
      .call(simple_bnch_call),
      .ret(simple_bnch_ret),
      .jal(simple_bnch_jal),
      .jalr(simple_bnch_jalr),
      .bnch_cond(simple_bnch_bnch_cond),
      .bm_pred_i(simple_bnch_bm_pred),
      .btype_i(simple_bnch_btype),
      .btb_vld_i(simple_bnch_btb_vld),
      .btb_target_i(simple_bnch_btb_target),
      .mts(simple_mts),
      .mtu(simple_mtu),
      .eq(simple_eq),
      .result_o(branch_unit_result),
      .*
  );
  //always_ff @(posedge cpu_clock_i) begin
  //  wb_valid_o <= !flush_i & valid_i & (auipc | jal | jalr) & !(dest_i == 0);
  //  res_valid_o <= !flush_i & valid_i;
  //  wb_dest_o <= dest_i;
  //  rob_o <= rob_id_i;
  //  if (((wrongful_nbranch&(brnch_res|(branch_type[1:0]!=2'b00)))|wrongful_target|wrongful_type|wrongful_bm)&& !flush_i && valid_i) begin
  //    rcu_excp_o <= 1;
  //    c1_btb_bm_mod_o <= 0;
  //    c1_call_affirm_o <= 0;
  //    c1_ret_affirm_o <= 0;
  //  end
  //      else if (!(wrongful_nbranch|wrongful_target|wrongful_type|wrongful_bm) && btb_vld_i && !flush_i && valid_i) begin
  //    c1_btb_bm_mod_o <= !(call | ret);
  //    c1_call_affirm_o <= call;
  //    c1_ret_affirm_o <= ret;
  //    rcu_excp_o <= 0;
  //  end else begin
  //    c1_btb_bm_mod_o <= 0;
  //    c1_call_affirm_o <= 0;
  //    c1_ret_affirm_o <= 0;
  //    rcu_excp_o <= 0;
  //  end
  //  c1_btb_way_o <= btb_way_i;
  //  c1_btb_vpc_o <= pc;
  //  c1_btb_target_o <= excp_addr;
  //  c1_cntr_pred_o <= bm_pred_i;
  //  c1_bnch_tkn_o <= (brnch_res | (branch_type[1:0] != 2'b00));
  //  c1_bnch_type_o <= branch_type;
  //  c1_bnch_present_o <= (brnch_res | (branch_type[1:0] != 2'b00));
  //end
endmodule

