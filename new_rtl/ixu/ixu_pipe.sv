module ixu_pipe (
    input  wire              core_clock_i,
    input  wire              core_reset_i,
    input  wire       [ 5:0] complex_rs1_i,
    input  wire       [ 5:0] complex_rs2_i,
    input  wire       [ 5:0] complex_rob_i,
    input  wire              complex_vld_i,
    output wire              complex_busy_o,
    input  wire       [ 5:0] simple_rs1_i,
    input  wire       [ 5:0] simple_rs2_i,
    input  wire       [ 5:0] simple_rob_i,
    input  wire              simple_vld_i,
    output wire logic [ 5:0] p0_rs1_o,
    output wire logic [ 5:0] p0_rs2_o,
    input  wire logic [31:0] p0_rs1_data_i,
    input  wire logic [31:0] p0_rs2_data_i,
    output wire logic [ 5:0] p1_rs1_o,
    output wire logic [ 5:0] p1_rs2_o,
    input  wire logic [31:0] p1_rs1_data_i,
    input  wire logic [31:0] p1_rs2_data_i
);
  //! Complex Path: Simple ALU (no bitmanip), Multiplication, Division
  //! Simple Path: Complex ALU, Branch
  reg [31:0] complex_a, simple_a;
  reg [31:0] complex_b, simple_b;
  reg [6:0] complex_op, simple_op;
  wire simple_mts, simple_mtu, simple_eq, complex_mts, complex_mtu, complex_eq;
  wire [31:0] complex_alu_result, complex_adder_result, simple_alu_result, simple_adder_result;


  // Register Read + Forward
  assign p0_rs1_o = complex_rs1_i;
  assign p0_rs2_o = complex_rs2_i;
  assign p1_rs1_o = simple_rs1_i;
  assign p1_rs2_o = simple_rs2_i;

  always_ff @(posedge core_clock_i) begin
    if (core_reset_i) begin
        
    end
  end

  // Execution
  biriq_alu #(
      .C_HAS_ZBA_EXTENSION  (1'b0),
      .C_HAS_ZBB_EXTENSION  (1'b0),
      .C_HAS_ZBS_EXTENSION  (1'b0),
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

  biriq_alu #(
      .C_HAS_ZBA_EXTENSION  (1'b1),
      .C_HAS_ZBB_EXTENSION  (1'b1),
      .C_HAS_ZBS_EXTENSION  (1'b1),
      .C_HAS_CZERO_EXTENSION(1'b1)
  ) complex_alu (
      .a_i(complex_a),
      .b_i(complex_b),
      .op_i(complex_op),
      .result_o(complex_alu_result),
      .adder_result_o(complex_adder_result),
      .mts_o(complex_mts),
      .mtu_o(complex_mtu),
      .eq_o(complex_eq)
  );



  // verilator lint_off UNUSED
  wire unused;
  assign unused = (|complex_adder_result) | complex_mts | complex_mtu | complex_eq | (|simple_adder_result) | simple_mts | simple_mtu | simple_eq;
  // verilator lint_on UNUSED
endmodule
