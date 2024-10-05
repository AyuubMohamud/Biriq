module uad16 (
    input   wire logic [15:0] a,
    input   wire logic [15:0] b,

    output  wire logic [15:0] c
);

    wire a_is_larger = a>b;

    wire [15:0] larger = a_is_larger ? a : b;
    wire [15:0] smaller = a_is_larger ? b : a;

    assign c = larger-smaller;
endmodule
