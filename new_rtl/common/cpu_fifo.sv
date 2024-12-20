// Copyright (C) Ayuub Mohamud, 2024
// Licensed under CERN-OHL-P version 2
module cpu_fifo #(
    parameter FW = 32,
    parameter DW = 32
) (
    input   wire logic          clk_i,
    input   wire logic          reset_i,

    // Write channel
    input   wire logic          wr_en_i,
    input   wire logic [DW-1:0] wr_data_i,
    output  wire logic          full_o,

    // Read side
    input   wire logic          rd_i,
    output  logic      [DW-1:0] rd_data_o,
    output  wire logic          empty_o
);

    reg [DW-1:0] fifo [0:FW-1];
    reg [$clog2(FW):0] read_ptr;
    reg [$clog2(FW):0] write_ptr;

    initial begin
        for (integer i = 0; i < FW; i = i + 1) begin
            fifo[i] = 0;
        end
        write_ptr = 0;
        read_ptr = 0;
    end
    assign empty_o = (read_ptr == write_ptr);
    assign full_o = (write_ptr[$clog2(FW)] != read_ptr[$clog2(FW)]) & (read_ptr[$clog2(FW)-1:0] == write_ptr[$clog2(FW)-1:0]);
    
    // Logic to handle the pointers
    always_ff @(posedge clk_i) begin
        if (reset_i) begin
            read_ptr <= 0;
            write_ptr <= 0;
        end
        if (~reset_i & wr_en_i & ~full_o) begin
            write_ptr <= write_ptr + 1;
        end
        if (~reset_i & rd_i & ~empty_o) begin
            read_ptr <= read_ptr + 1;
        end
    end
    // Logic to handle memories
    always_ff @(posedge clk_i) begin
        if (~reset_i & wr_en_i & ~full_o) begin
            fifo[write_ptr[$clog2(FW)-1:0]] <= wr_data_i;
        end
    end
    assign rd_data_o = fifo[read_ptr[$clog2(FW)-1:0]];
endmodule
