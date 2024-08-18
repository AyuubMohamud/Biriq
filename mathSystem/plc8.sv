module plc8 (
    input   wire logic [7:0] a,
    output       logic [3:0] b
);
    reg [3:0] cpop_lkp_table [0:255];
    initial begin
        $readmemh("plc8.mem", cpop_lkp_table);
    end
    assign b = cpop_lkp_table[a];
endmodule
