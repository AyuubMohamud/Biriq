module dbraminst (
    input   wire logic clk,
    input   wire logic        rd_en,
    input   wire logic [9:0] rd_addr,
    output       logic [63:0] rd_data,
    input   wire logic [7:0]  wr_en,
    input   wire logic [9:0] wr_addr,
    input   wire logic [63:0] wr_data
);
    reg [63:0] ram [0:1023];
    always_ff @(posedge clk) begin
        if (rd_en) begin
            rd_data <= ram[rd_addr];
        end
        if (wr_en[7]) begin
            ram[wr_addr][63:56] <= wr_data[63:56];
        end
        if (wr_en[6]) begin
            ram[wr_addr][55:48] <= wr_data[55:48];
        end
        if (wr_en[5]) begin
            ram[wr_addr][47:40] <= wr_data[47:40];
        end
        if (wr_en[4]) begin
            ram[wr_addr][39:32] <= wr_data[39:32];
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
