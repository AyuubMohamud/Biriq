module ivmul (
    input   wire logic [31:0]   a,
    input   wire logic [31:0]   b,
    input   wire logic [1:0]    opc,
    output       logic [31:0]   result
);

    wire [31:0] mul_result_0 = $signed(a[15:0])*$signed(b[15:0]);
    wire [31:0] mul_result_1 = $signed(a[31:16])*$signed(b[31:16]);

    wire [31:0] accumulator = mul_result_0+mul_result_1;

    always_comb begin
        case (opc)
            2'b00: begin
                result = {mul_result_1[15:0],mul_result_0[15:0]};
            end
            2'b01: begin
                result = {mul_result_1[31:16],mul_result_0[31:16]};
            end
            2'b10: begin
                result = accumulator;
            end
            default: result = 'x;
        endcase
    end
endmodule
