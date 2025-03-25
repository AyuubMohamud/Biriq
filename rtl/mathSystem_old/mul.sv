module mul (
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [ 1:0] op,
    output wire [31:0] res
);
  wire [32:0] a1, b1;
  assign a1 = {op == 2'b10 ? 1'b0 : a[31], a[31:0]};
  assign b1 = {op[1] ? 1'b0 : b[31], b[31:0]};
  wire [65:0] result;
  assign result = $signed(a1) * $signed(b1);

  assign res = op == 2'b00 ? result[31:0] : result[63:32];
endmodule

