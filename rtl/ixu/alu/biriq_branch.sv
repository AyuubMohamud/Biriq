
/*
op_i == 3'b000: maxu
op_i == 3'b001: minu
op_i == 3'b010: slt
op_i == 3'b011: sltu
op_i == 3'b100: max
op_i == 3'b101: min
op_i == 3'b110: czero.eqz
op_i == 3'b111: czero.nez
*/
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
