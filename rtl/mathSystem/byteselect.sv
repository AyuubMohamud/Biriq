module byteselect (
    input   wire logic [31:0] a,
    input   wire logic [1:0]  b,
    output       logic [7:0]  c
);

    always_comb begin
        case (b)
            2'd0: begin
                c = a[7:0];
            end
            2'd1: begin
                c = a[15:8];
            end
            2'd2: begin
                c = a[23:16];
            end
            2'd3: begin
                c = a[31:24];
            end
        endcase
    end

endmodule
