module iiie_alu #(
    `include "iiie_config.svh"
) (
    input wire [31:0] a,
    input wire [31:0] b,
    input wire [5:0] aluop,
    input wire [1:0] func3_l2,
    output logic [31:0] out,
    output wire lt_o,
    output wire eq_o
);
  `include "iiie_ops.svh"

  wire sub;
  wire inv_b;
  wire [31:0] adder;
  wire [31:0] add_b;
  wire [31:0] preshift;
  wire unsigned_lt;
  assign unsigned_lt = (aluop == `ALU_SLTU) || (|C_HAS_ZBB && ((aluop == `ALU_MINU) || (aluop == `ALU_MAXU)));
  assign sub = !(aluop == `ALU_ADD || ((|C_HAS_ZBA) && (aluop == `ALU_SHXADD)));
  assign inv_b = sub & !((aluop == `ALU_AND) || (aluop == `ALU_OR) || (aluop == `ALU_XOR));
  assign add_b = inv_b ? ~b : b;
  assign preshift = |C_HAS_ZBA ? a << ((aluop == `ALU_SHXADD) ? func3_l2[1:0]==2'b01 ? 2'd1 : func3_l2[1:0]==2'b10 ? 2'd2 : 2'd3 : 2'd0) : a;
  assign adder = preshift + add_b + {31'd0, sub};
  assign eq_o = ~(|adder);
  assign lt_o = a[31] == b[31] ? adder[31] : unsigned_lt ? b[31] : a[31];

  wire rev_a;
  assign rev_a = (aluop==`ALU_SLL) || (|C_HAS_ZBB && ((aluop==`ALU_ROL) || (aluop == `ALU_BCLR) || (aluop==`ALU_BINV) || (aluop==`ALU_BSET)));

  wire [31:0] reved_a;
  for (genvar k = 0; k < 32; k++) begin : _bit_reversal
    assign reved_a[k] = rev_a ? a[31-k] : a[k];
  end
  logic [5:0] ctz_res;
  logic [5:0] cpop_result;
  always_comb begin
    casez (reved_a)
      32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz1: ctz_res = 0;
      32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz10: ctz_res = 1;
      32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzz100: ctz_res = 2;
      32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzz1000: ctz_res = 3;
      32'bzzzzzzzzzzzzzzzzzzzzzzzzzzz10000: ctz_res = 4;
      32'bzzzzzzzzzzzzzzzzzzzzzzzzzz100000: ctz_res = 5;
      32'bzzzzzzzzzzzzzzzzzzzzzzzzz1000000: ctz_res = 6;
      32'bzzzzzzzzzzzzzzzzzzzzzzzz10000000: ctz_res = 7;
      32'bzzzzzzzzzzzzzzzzzzzzzzz100000000: ctz_res = 8;
      32'bzzzzzzzzzzzzzzzzzzzzzz1000000000: ctz_res = 9;
      32'bzzzzzzzzzzzzzzzzzzzzz10000000000: ctz_res = 10;
      32'bzzzzzzzzzzzzzzzzzzzz100000000000: ctz_res = 11;
      32'bzzzzzzzzzzzzzzzzzzz1000000000000: ctz_res = 12;
      32'bzzzzzzzzzzzzzzzzzz10000000000000: ctz_res = 13;
      32'bzzzzzzzzzzzzzzzzz100000000000000: ctz_res = 14;
      32'bzzzzzzzzzzzzzzzz1000000000000000: ctz_res = 15;
      32'bzzzzzzzzzzzzzzz10000000000000000: ctz_res = 16;
      32'bzzzzzzzzzzzzzz100000000000000000: ctz_res = 17;
      32'bzzzzzzzzzzzzz1000000000000000000: ctz_res = 18;
      32'bzzzzzzzzzzzz10000000000000000000: ctz_res = 19;
      32'bzzzzzzzzzzz100000000000000000000: ctz_res = 20;
      32'bzzzzzzzzzz1000000000000000000000: ctz_res = 21;
      32'bzzzzzzzzz10000000000000000000000: ctz_res = 22;
      32'bzzzzzzzz100000000000000000000000: ctz_res = 23;
      32'bzzzzzzz1000000000000000000000000: ctz_res = 24;
      32'bzzzzzz10000000000000000000000000: ctz_res = 25;
      32'bzzzzz100000000000000000000000000: ctz_res = 26;
      32'bzzzz1000000000000000000000000000: ctz_res = 27;
      32'bzzz10000000000000000000000000000: ctz_res = 28;
      32'bzz100000000000000000000000000000: ctz_res = 29;
      32'bz1000000000000000000000000000000: ctz_res = 30;
      32'b10000000000000000000000000000000: ctz_res = 31;
      default: ctz_res = 32;
    endcase
  end
  always_comb begin
    cpop_result = 0;
    for (integer i = 0; i < 32; i++) begin
      /* verilator lint_off WIDTHEXPAND */
      cpop_result += a[i];
      /* verilator lint_on WIDTHEXPAND */
    end
  end

  logic [31:0] gates;
  always_comb
    case (aluop[1:0])
      2'b00:   gates = a ^ add_b;
      2'b01:   gates = a | add_b;
      2'b10:   gates = a & add_b;
      default: gates = 'x;
    endcase

  wire rotate;
  wire arith;
  wire mask;
  assign rotate = |C_HAS_ZBB && ((aluop == `ALU_ROL) || (aluop == `ALU_ROR));
  assign mask   = |C_HAS_ZBS && ((aluop == `ALU_BCLR) || (aluop == `ALU_BINV) || (aluop == `ALU_BSET));
  assign arith = (aluop == `ALU_SRA);
  wire [31:0] shift_operand1;
  wire [31:0] shift_stage1;
  wire [31:0] shift_res_stage1;
  wire [31:0] shift_stage2;
  wire [31:0] shift_res_stage2;
  wire [31:0] shift_stage3;
  wire [31:0] shift_res_stage3;
  wire [31:0] shift_stage4;
  wire [31:0] shift_res_stage4;
  wire [31:0] shift_stage5;
  wire [31:0] shift_res_stage5;
  assign shift_operand1 = mask ? 32'd1 : reved_a;
  assign shift_stage1[31] = rotate ? shift_operand1[0] : arith ? a[31] : 1'b0;
  assign shift_stage1[30:0] = shift_operand1[31:1];
  assign shift_res_stage1 = b[0] ? shift_stage1 : shift_operand1;
  assign shift_stage2[31:30] = rotate ? shift_res_stage1[1:0] : arith ? {{2{a[31]}}} : 2'b00;
  assign shift_stage2[29:0] = shift_res_stage1[31:2];
  assign shift_res_stage2 = b[1] ? shift_stage2 : shift_res_stage1;
  assign shift_stage3[31:28] = rotate ? shift_res_stage2[3:0] : arith ? {{4{a[31]}}} : 4'b00;
  assign shift_stage3[27:0] = shift_res_stage2[31:4];
  assign shift_res_stage3 = b[2] ? shift_stage3 : shift_res_stage2;
  assign shift_stage4[31:24] = rotate ? shift_res_stage3[7:0] : arith ? {{8{a[31]}}} : 8'b00;
  assign shift_stage4[23:0] = shift_res_stage3[31:8];
  assign shift_res_stage4 = b[3] ? shift_stage4 : shift_res_stage3;
  assign shift_stage5[31:16] = rotate ? shift_res_stage4[15:0] : arith ? {{16{a[31]}}} : 16'b00;
  assign shift_stage5[15:0] = shift_res_stage4[31:16];
  assign shift_res_stage5 = b[4] ? shift_stage5 : shift_res_stage4;

  wire [31:0] shift_res;
  for (genvar k = 0; k < 32; k++) begin : _flip_back
    assign shift_res[k] = rev_a ? shift_res_stage5[31-k] : shift_res_stage5[k];
  end

  wire cond_rev;
  wire cond_sel;
  assign cond_rev = |C_HAS_ZBB && ((aluop == `ALU_MAX) || (aluop == `ALU_MAXU));
  assign cond_sel = cond_rev ? ~lt_o : lt_o;

  wire [31:0] comparison;
  assign comparison = cond_sel ? a : b;

  wire [31:0] extension;
  assign extension = aluop == `ALU_SEXTB ? {{24{a[7]}}, a[7:0]} : aluop == `ALU_SEXTH ? {{16{a[15]}}, a[15:0]} : {16'd0, a[15:0]};

  logic [31:0] zip;
  logic [31:0] unzip;
  logic [31:0] pack;
  logic [31:0] packh;
  always_comb begin
    for (integer i = 0; i < 16; i++) begin
      zip[2*i]    = a[i];
      zip[2*i+1]  = a[i+16];
      unzip[i]    = a[2*i];
      unzip[i+16] = a[2*i+1];
    end
    pack  = {b[15:0], a[15:0]};
    packh = {16'h0, b[7:0], a[7:0]};
  end

  logic [3:0] xperm4 [0:7];
  logic [7:0] xperm8 [0:3];
  logic [3:0] xsrc4  [0:7];
  logic [7:0] xsrc8  [0:3];
  logic [3:0] xidx4  [0:7];
  logic [7:0] xidx4r;
  logic [7:0] xidx8  [0:3];
  logic [3:0] xidx8r;
  for (genvar i = 0; i < 8; i++) begin : __xsrc4
    assign xsrc4[i] = b[4*(i+1)-1:4*i];
  end
  for (genvar i = 0; i < 4; i++) begin : __xsrc8
    assign xsrc8[i] = b[8*(i+1)-1:8*i];
  end
  for (genvar i = 0; i < 8; i++) begin : __xidx4
    assign xidx4[i]  = a[4*(i+1)-1:4*i];
    assign xidx4r[i] = a[4*(i+1)-1:4*i] > 4'd7;
  end
  for (genvar i = 0; i < 4; i++) begin : __xidx8
    assign xidx8[i]  = a[8*(i+1)-1:8*i];
    assign xidx8r[i] = a[8*(i+1)-1:8*i] > 8'd3;
  end

  always_comb begin
    for (integer i = 0; i < 8; i++) begin
      xperm4[i] = xidx4r[i] ? '0 : xsrc4[xidx4[i][2:0]];
    end
    for (integer i = 0; i < 4; i++) begin
      xperm8[i] = xidx8r[i] ? '0 : xsrc8[xidx8[i][1:0]];
    end
  end


  always_comb begin
    casez ({
      |C_HAS_ZBKB, |C_HAS_ZBKX, |C_HAS_ZBA, |C_HAS_ZBB, |C_HAS_ZBS, aluop
    })
      // base integer set
      {5'bzzzzz, `ALU_ADD} : out = adder;
      {5'bzzzzz, `ALU_SUB} : out = adder;
      {5'bzzzzz, `ALU_SLL} : out = shift_res;
      {5'bzzzzz, `ALU_SLT} : out = {31'd0, lt_o};
      {5'bzzzzz, `ALU_SLTU} : out = {31'd0, lt_o};
      {5'bzzzzz, `ALU_XOR} : out = gates;
      {5'bzzzzz, `ALU_AND} : out = gates;
      {5'bzzzzz, `ALU_OR} : out = gates;
      {5'bzzzzz, `ALU_SRL} : out = shift_res;
      {5'bzzzzz, `ALU_SRA} : out = shift_res;
      // zba
      {5'bzz1zz, `ALU_SHXADD} : out = adder;
      // zbb
      {5'bzzz1z, `ALU_ANDN} : out = gates;
      {5'bzzz1z, `ALU_ORN} : out = gates;
      {5'bzzz1z, `ALU_XNOR} : out = gates;
      {5'bzzz1z, `ALU_CTZ} : out = {26'd0, ctz_res};
      {5'bzzz1z, `ALU_CLZ} : out = {26'd0, ctz_res};
      {5'bzzz1z, `ALU_CPOP} : out = {26'd0, cpop_result};
      {5'bzzz1z, `ALU_MAX} : out = comparison;
      {5'bzzz1z, `ALU_MAXU} : out = comparison;
      {5'bzzz1z, `ALU_MIN} : out = comparison;
      {5'bzzz1z, `ALU_MINU} : out = comparison;
      {5'bzzz1z, `ALU_ROR} : out = shift_res;
      {5'bzzz1z, `ALU_ROL} : out = shift_res;
      {5'bzzz1z, `ALU_SEXTH} : out = extension;
      {5'bzzz1z, `ALU_SEXTB} : out = extension;
      {5'bzzz1z, `ALU_ZEXTH} : out = extension;
      {5'bzzz1z, `ALU_REV8} : out = {a[7:0], a[15:8], a[23:16], a[31:24]};
      {5'bzzz1z, `ALU_ORCB} : out = {{8{|a[31:24]}}, {8{|a[23:16]}}, {8{|a[15:8]}}, {8{|a[7:0]}}};
      // zbs
      {5'bzzzz1, `ALU_BEXT} : out = {31'd0, shift_res[0]};
      {5'bzzzz1, `ALU_BCLR} : out = a & ~shift_res;
      {5'bzzzz1, `ALU_BINV} : out = a ^ shift_res;
      {5'bzzzz1, `ALU_BSET} : out = a | shift_res;
      // zbkb
      {5'b1zzzz, `ALU_PACK} : out = pack;
      {5'b1zzzz, `ALU_PACKH} : out = packh;
      {5'b1zzzz, `ALU_ZIP} : out = zip;
      {5'b1zzzz, `ALU_UNZIP} : out = unzip;
      {5'b1zzzz, `ALU_BREV8} : out = {reved_a[31:24], reved_a[23:16], reved_a[15:8], reved_a[7:0]};
      // zbkx
      {5'bz1zzz, `ALU_XPERM8} : out = {xperm8[3], xperm8[2], xperm8[1], xperm8[0]};
      {5'bz1zzz, `ALU_XPERM4} : out = {xperm4[7], xperm4[6], xperm4[5], xperm4[4], xperm4[3], xperm4[2], xperm4[1], xperm4[0]};
      default: out = 'x;
    endcase
  end


endmodule
