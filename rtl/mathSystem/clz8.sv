module clz8 (
    input   wire logic [7:0] a,
    output       logic [3:0] b
);
    always_comb begin
        casez (a)
            8'bzzzzzzz1: begin b = 0;end
            8'bzzzzzz10: begin b = 1;end
            8'bzzzzz100: begin b = 2;end
            8'bzzzz1000: begin b = 3;end
            8'bzzz10000: begin b = 4;end
            8'bzz100000: begin b = 5;end
            8'bz1000000: begin b = 6;end
            8'b10000000: begin b = 7;end
            default:     begin b = 8;end 
        endcase
    end
endmodule
