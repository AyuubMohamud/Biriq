module ixu_sc_pipe (
    input  wire         core_clock_i,
    input  wire         core_flush_i,
    // Queue <-> IXU Single Cycle pipe
    input  wire  [17:0] data_i,
    input  wire         valid_i,
    // IXU Single Cycle Pipe <-> Integer Register File
    output wire  [ 5:0] rs1_o,
    output wire  [ 5:0] rs2_o,
    input  wire  [31:0] rs1_data_i,
    input  wire  [31:0] rs2_data_i,
    // IXU Single Cycle Pipe <-> Instruction RAM (IXU)
    output wire  [ 4:0] rob_o,
    input  wire  [ 6:0] opcode_i,
    input  wire  [ 6:0] ins_type,
    input  wire         imm_i,
    input  wire  [31:0] immediate_i,
    input  wire  [ 5:0] dest_i,
    input  wire  [ 1:0] hint_i,
    // IXU Single Cycle Pipe <-> Branch Information RAM
    input  wire  [29:0] pc_i,
    input  wire  [ 1:0] bm_pred_i,
    input  wire  [ 1:0] btype_i,
    input  wire         btb_vld_i,
    input  wire  [29:0] btb_target_i,
    input  wire         btb_way_i,
    input  wire         btb_idx_i,
    // IXU Single Cycle <-> Instruction Wakeup
    output logic [ 5:0] wakeup_dest,
    output logic        wakeup_valid,
    // IXU Single Cycle <-> Integer Register File
    output logic [ 5:0] ixu_sc_ex_dest,
    output logic [31:0] ixu_sc_ex_data,
    output logic        ixu_sc_ex_valid,
    output logic [ 5:0] ixu_sc_wb_dest,
    output logic [31:0] ixu_sc_wb_data,
    output logic        ixu_sc_wb_valid,
    // IXU Single Cycle <-> PMU
    output wire  [ 5:0] pmu_excp_rob_o,
    output wire  [ 4:0] pmu_excp_code_o,
    output wire         pmu_excp_valid_o,
    output wire  [29:0] pmu_btb_vpc_o,
    output wire  [29:0] pmu_btb_target_o,
    output wire  [ 1:0] pmu_cntr_pred_o,
    output wire         pmu_bnch_tkn_o,
    output wire  [ 1:0] pmu_bnch_type_o,
    output wire         pmu_call_affirm_o,
    output wire         pmu_ret_affirm_o,
    output wire         pmu_btb_way_o,
    output wire         pmu_btb_bm_mod_o,
    output wire  [ 4:0] pmu_ins_id_o,
    output wire         pmu_ins_valid_o
);
  assign rob_o = data_i[4:0];
  assign rs1_o = data_i[11:6];
  assign rs2_o = data_i[17:12];
  initial wakeup_valid = 0;
  /** Execute Registers and Wires **/
  reg  [31:0] a;
  reg  [31:0] b;
  reg  [ 6:0] opc;
  reg  [ 5:0] ex_dest;
  reg  [ 5:0] ex_rob;
  reg         ex_valid;
  reg         ex_alu;
  reg         ex_fwd;
  wire [31:0] ex_alu_result;
  wire [31:0] ex_br_result;
  wire [31:0] ex_adder_result;
  wire        mts;
  wire        mtu;
  wire        eq;
  reg  [31:0] bnch_offset;
  reg  [29:0] bnch_pc;
  reg         bnch_auipc;
  reg         bnch_call;
  reg         bnch_ret;
  reg         bnch_jal;
  reg         bnch_jalr;
  reg  [ 1:0] bnch_bm_pred;
  reg  [ 1:0] bnch_btype;
  reg         bnch_btb_vld;
  reg  [29:0] bnch_btb_target;
  reg         bnch_btb_way;
  wire        brnch_res;
  wire [ 1:0] branch_type;
  wire [31:0] excp_addr;
  /** Writeback Stage Registers and Wires **/
  reg         wb_auipc;
  reg         wb_brnch_res;
  reg  [ 1:0] wb_branch_type;
  reg  [31:0] wb_excp_addr;
  reg  [29:0] wb_pc;
  reg         wb_call;
  reg         wb_ret;
  reg  [ 1:0] wb_bm_pred;
  reg  [ 1:0] wb_btype;
  reg         wb_btb_vld;
  reg  [29:0] wb_btb_target;
  reg         wb_btb_way;
  reg  [31:0] wb_data;
  reg  [ 5:0] wb_dest;
  reg  [ 5:0] wb_rob;
  reg         wb_fwd;
  reg         wb_valid;
  reg         wb_alu;
  wire        wrongful_nbranch;
  wire        wrongful_target;
  wire        wrongful_type;
  wire        wrongful_bm;

  always_ff @(posedge core_clock_i) begin
    a <= ins_type[3] ? 32'd0 : rs1_data_i;
    b <= imm_i | ins_type[3] ? immediate_i : rs2_data_i;
    opc <= ins_type[3] ? 7'd0 : opcode_i;
    bnch_offset <= immediate_i;
    {wb_pc, bnch_pc} <= {bnch_pc, {pc_i[29:1], pc_i[0] ? 1'b1 : data_i[0]}};
    {wb_auipc, bnch_auipc} <= {bnch_auipc, ins_type[4]};
    bnch_jal <= ins_type[1];
    bnch_jalr <= ins_type[2];
    {wb_bm_pred, bnch_bm_pred} <= {bnch_bm_pred, bm_pred_i};
    {wb_btype, bnch_btype} <= {bnch_btype, btype_i};
    {wb_btb_vld, bnch_btb_vld} <= {
      bnch_btb_vld, btb_vld_i & (btb_idx_i == (pc_i[0] ? 1'b1 : data_i[0]))
    };
    {wb_btb_target, bnch_btb_target} <= {bnch_btb_target, btb_target_i};
    {wb_btb_way, bnch_btb_way} <= {bnch_btb_way, btb_way_i};  // mask off appropriately
    {wb_call, bnch_call} <= {bnch_call, hint_i[1]};
    {wb_ret, bnch_ret} <= {bnch_ret, hint_i[0]};
    wb_brnch_res <= brnch_res;
    wb_excp_addr <= excp_addr;
    wb_branch_type <= branch_type;
  end

  always_ff @(posedge core_clock_i) {wb_dest, ex_dest} <= {ex_dest, dest_i};

  always_ff @(posedge core_clock_i) {wb_rob, ex_rob} <= {ex_rob, data_i[5:0]};

  always_ff @(posedge core_clock_i)
    if (core_flush_i) {wb_valid, ex_valid} <= '0;
    else {wb_valid, ex_valid} <= {ex_valid, valid_i};

  always_ff @(posedge core_clock_i) {wb_alu, ex_alu} <= {ex_alu, ins_type[0] | ins_type[3]};

  always_ff @(posedge core_clock_i)
    if (core_flush_i) {wb_fwd, ex_fwd} <= '0;
    else {wb_fwd, ex_fwd} <= {ex_fwd, (|ins_type) & valid_i & (dest_i != '0)};

  always_ff @(posedge core_clock_i) wb_data <= ixu_sc_ex_data;

  assign ixu_sc_ex_dest = ex_dest;
  assign ixu_sc_ex_data = ex_alu ? ex_alu_result : ex_br_result;
  assign ixu_sc_ex_valid = ex_fwd;
  assign ixu_sc_wb_dest = wb_dest;
  assign ixu_sc_wb_data = wb_data;
  assign ixu_sc_wb_valid = wb_fwd;
  assign wakeup_dest = dest_i;
  assign wakeup_valid = valid_i & (|ins_type);
  assign pmu_ins_id_o = wb_rob[4:0];
  assign pmu_ins_valid_o = wb_valid;
  assign pmu_excp_rob_o = wb_rob;
  assign pmu_excp_code_o = wb_excp_addr[1] ? 5'b00000 : 5'b10000;
  assign pmu_excp_valid_o = ((wrongful_nbranch&(wb_brnch_res|(wb_branch_type[1:0]!=2'b00)))|wrongful_target|wrongful_type|wrongful_bm)&&!wb_alu&&wb_valid;
  assign pmu_btb_vpc_o = wb_pc;
  assign pmu_btb_target_o = wb_excp_addr[31:2];
  assign pmu_cntr_pred_o = wb_bm_pred;
  assign pmu_bnch_tkn_o = wb_brnch_res || (wb_branch_type != 2'b00);
  assign pmu_bnch_type_o = wb_branch_type;
  assign pmu_btb_way_o = wb_btb_way;
  assign pmu_btb_bm_mod_o = !(wrongful_nbranch|wrongful_target|wrongful_type|wrongful_bm) && wb_btb_vld && !(wb_call || wb_ret) && !wb_alu && wb_valid;
  assign pmu_call_affirm_o = wb_call & !wb_alu;
  assign pmu_ret_affirm_o = wb_ret & !wb_alu;
  assign wrongful_nbranch = !wb_btb_vld && !wb_auipc;
  assign wrongful_target = {wb_btb_target, 2'b00} != wb_excp_addr && wb_btb_vld;
  assign wrongful_type = wb_branch_type != wb_btype && wb_btb_vld;
  assign wrongful_bm = (wb_brnch_res ^ wb_bm_pred[1]) && wb_btb_vld && wb_branch_type == 2'b00;
  biriq_alu #(
      .C_HAS_ZBA_EXTENSION  (1'b1),
      .C_HAS_ZBB_EXTENSION  (1'b1),
      .C_HAS_ZBS_EXTENSION  (1'b1),
      .C_HAS_CZERO_EXTENSION(1'b1)
  ) biriq_alu_inst (
      .a_i(a),
      .b_i(b),
      .op_i(opc),
      .result_o(ex_alu_result),
      .adder_result_o(ex_adder_result),
      .mts_o(mts),
      .mtu_o(mtu),
      .eq_o(eq)
  );
  ixu_branchunit branchUnit_inst (
      .mts(mts),
      .mtu(mtu),
      .operand_1(a),
      .operand_2(b),
      .offset(bnch_offset),
      .pc(bnch_pc),
      .auipc(bnch_auipc),
      .call(bnch_call),
      .ret(bnch_ret),
      .jal(bnch_jal),
      .jalr(bnch_jalr),
      .bnch_cond(opc[2:0]),
      .result_o(ex_br_result),
      .*
  );

  // verilator lint_off UNUSED
  wire unused;
  assign unused = |ex_adder_result | eq;
  // verilator lint_on UNUSED


endmodule
