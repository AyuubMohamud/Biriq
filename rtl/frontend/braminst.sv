module braminst (
    input   wire logic clk,
    input   wire logic        rd_en,
    input   wire logic [9:0] rd_addr,
    output       logic [63:0] rd_data,
    input   wire logic        wr_en,
    input   wire logic [9:0] wr_addr,
    input   wire logic [63:0] wr_data
);
    reg [63:0] ram [0:1023];
    always_ff @(posedge clk) begin
        if (rd_en) begin
            rd_data <= ram[rd_addr];
        end
        if (wr_en) begin
            ram[wr_addr] <= wr_data;
        end
    end

endmodule
