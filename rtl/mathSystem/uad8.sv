module uad8 (
    input   wire logic [7:0] a,
    input   wire logic [7:0] b,
    output  wire logic [7:0] c
);
    wire a_is_larger = a>b;
    
    wire [7:0] larger = a_is_larger ? a : b;
    wire [7:0] smaller = a_is_larger ? b : a;

    assign c = larger-smaller;
endmodule
