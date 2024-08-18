module dbraminst (
    input   wire logic clk,
    input   wire logic        rd_en,
    input   wire logic [10:0] rd_addr,
    output       logic [31:0] rd_data,
    input   wire logic [3:0]  wr_en,
    input   wire logic [10:0] wr_addr,
    input   wire logic [31:0] wr_data
);
    reg [31:0] ram [0:2047];
    always_ff @(posedge clk) begin
        if (rd_en) begin
            rd_data <= ram[rd_addr];
        end
        if (wr_en[3]) begin
            ram[wr_addr][31:24] <= wr_data[31:24];
        end
        if (wr_en[2]) begin
            ram[wr_addr][23:16] <= wr_data[23:16];
        end
        if (wr_en[1]) begin
            ram[wr_addr][15:8] <= wr_data[15:8];
        end
        if (wr_en[0]) begin
            ram[wr_addr][7:0] <= wr_data[7:0];
        end
    end
endmodule
