module onehot6to1 (
    input   wire logic [5:0]        a,
    output       logic              onehot
);
    always_comb begin
        case (a)
            6'b000001: begin
                onehot = 1'b1;
            end
            6'b000010: begin
                onehot = 1'b1;
            end
            6'b000100: begin
                onehot = 1'b1;
            end
            6'b001000: begin
                onehot = 1'b1;
            end
            6'b010000: begin
                onehot = 1'b1;
            end
            6'b100000: begin
                onehot = 1'b1;
            end
            default: begin
                onehot = 1'b0;
            end
        endcase
    end
endmodule
