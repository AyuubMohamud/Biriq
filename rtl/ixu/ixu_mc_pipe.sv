module ixu_mc_pipe (
    input  wire         core_clock_i,
    input  wire         core_flush_i,
    // Queue <-> IXU Multi Cycle pipe
    input  wire  [17:0] data_i,
    input  wire         valid_i,
    output logic        busy_o,
    // IXU Multi Cycle Pipe <-> Integer Register File
    output wire  [ 5:0] rs1_o,
    output wire  [ 5:0] rs2_o,
    input  wire  [31:0] rs1_data_i,
    input  wire  [31:0] rs2_data_i,
    // IXU Multi Cycle Pipe <-> Instruction RAM (IXU)
    output wire  [ 4:0] rob_o,
    input  wire  [ 6:0] opcode_i,
    input  wire  [ 6:0] ins_type,
    input  wire         imm_i,
    input  wire  [31:0] immediate_i,
    input  wire  [ 5:0] dest_i,
    // IXU Multi Cycle <-> Instruction Wakeup
    output logic [ 5:0] wakeup_dest,
    output logic        wakeup_valid,
    // IXU Multi Cycle <-> Integer Register File
    output logic [ 5:0] ixu_mc_ex_dest,
    output logic [31:0] ixu_mc_ex_data,
    output logic        ixu_mc_ex_valid,
    output logic [ 5:0] ixu_mc_wb_dest,
    output logic [31:0] ixu_mc_wb_data,
    output logic        ixu_mc_wb_valid,
    // IXU Multi Cycle <-> PMU
    output wire  [ 4:0] pmu_ins_id_o,
    output wire         pmu_ins_valid_o
);
  // 0 = ALU, 1 = JAL, 2 = JALR, 3 = LUI, 4 = AUIPC, 5 = Mul, 6 = Div
  assign rob_o = data_i[4:0];
  assign rs1_o = data_i[11:6];
  assign rs2_o = data_i[17:12];
  initial wakeup_valid = 0;
  /** Execute Registers and Wires **/
  typedef enum {
    IDLE,
    DIVISION
  } mc_pipe_state_t;
  mc_pipe_state_t        mc_pipe_state;
  reg             [31:0] a;
  reg             [31:0] b;
  reg             [ 6:0] opc;
  reg             [ 5:0] ex_dest;
  reg             [ 5:0] ex_rob;
  reg                    ex_valid;
  reg             [ 1:0] ex_type;
  reg                    ex_fwd;
  reg                    div_ex;
  wire            [31:0] ex_alu_result;
  wire            [31:0] ex_mul_result;
  wire            [31:0] ex_div_result;
  wire            [31:0] ex_adder_result;
  wire                   mts;
  wire                   mtu;
  wire                   eq;
  wire                   div_busy;
  wire                   div_done;
  wire                   div_dbz;
  wire                   div_overflow;
  wire                   div_valid;
  /** Writeback Stage Registers and Wires **/
  reg             [31:0] wb_data;
  reg             [ 5:0] wb_dest;
  reg             [ 5:0] wb_rob;
  reg                    wb_fwd;
  reg                    wb_valid;
  //assign div_ex = valid_i & (type_i == 2'b10) & !div_busy;
  //assign busy_o = (valid_i & (type_i == 2'b10) & !div_busy) || div_ex || div_busy;
  always_ff @(posedge core_clock_i) begin
    a   <= ins_type[3] ? 32'd0 : rs1_data_i;
    b   <= imm_i | ins_type[3] ? immediate_i : rs2_data_i;
    opc <= ins_type[3] ? 7'd0 : opcode_i;
  end
  always_ff @(posedge core_clock_i) {wb_dest, ex_dest} <= {ex_dest, dest_i};
  always_ff @(posedge core_clock_i) {wb_rob, ex_rob} <= {ex_rob, data_i[5:0]};
  always_ff @(posedge core_clock_i)
    if (core_flush_i) {wb_valid, ex_valid} <= '0;
    else {wb_valid, ex_valid} <= {ex_valid & !(ins_type[6] && !div_done), valid_i};
  always_ff @(posedge core_clock_i) {ex_type} <= ins_type[6] ? 2'b10 : ins_type[5] ? 2'b01 : 2'b00;
  always_ff @(posedge core_clock_i)
    if (core_flush_i) {wb_fwd, ex_fwd} <= '0;
    else
      {wb_fwd, ex_fwd} <= {
        ex_fwd & !(ins_type[6] && !div_done), (|ins_type) & valid_i & (dest_i != '0)
      };
  always_ff @(posedge core_clock_i) wb_data <= ixu_mc_ex_data;

  always_comb
    case (mc_pipe_state)
      IDLE: busy_o = valid_i & ins_type[6];
      DIVISION: busy_o = !div_done;
    endcase

  always_ff @(posedge core_clock_i)
    if (core_flush_i) mc_pipe_state <= IDLE;
    else
      case (mc_pipe_state)
        IDLE: if (valid_i & ins_type[6]) mc_pipe_state <= DIVISION;
        DIVISION: if (div_done) mc_pipe_state <= IDLE;
      endcase
  always_ff @(posedge core_clock_i)
    if (core_flush_i) div_ex <= 1'b0;
    else
      case (mc_pipe_state)
        IDLE: if (valid_i & ins_type[6]) div_ex <= 1'b1;
        DIVISION: div_ex <= 1'b0;
      endcase

  assign ixu_mc_ex_dest = ex_dest;
  assign ixu_mc_ex_data = ex_type == 2'b00 ? ex_alu_result : ex_type == 2'b01 ? ex_mul_result : ex_div_result;
  assign ixu_mc_ex_valid = ex_fwd & !(ins_type[6] && !div_done);
  assign ixu_mc_wb_dest = wb_dest;
  assign ixu_mc_wb_data = wb_data;
  assign ixu_mc_wb_valid = wb_fwd;
  assign wakeup_dest = ex_dest;
  assign wakeup_valid = ex_fwd & !(ins_type[6] && !div_done);
  assign pmu_ins_id_o = wb_rob[4:0];
  assign pmu_ins_valid_o = wb_valid;

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

  ixu_mul mul_inst (
      .a  (a),
      .b  (b),
      .op (opc[1:0]),
      .res(ex_mul_result)
  );

  ixu_div division_inst (
      .core_clock_i(core_clock_i),
      .core_flush_i(core_flush_i),
      .start(div_ex),
      .unsigned_i(opc[0]),
      .opcode_i(opc[1]),
      .busy(div_busy),
      .done(div_done),
      .valid(div_valid),
      .dbz(div_dbz),
      .overflow(div_overflow),
      .a_i(a),
      .b_i(b),
      .res(ex_div_result)
  );

  // verilator lint_off UNUSED
  wire unused;
  assign unused = |ex_adder_result | mts | mtu | eq | div_dbz | div_overflow | div_valid | div_busy | wb_rob[5];
  // verilator lint_on UNUSED


endmodule
