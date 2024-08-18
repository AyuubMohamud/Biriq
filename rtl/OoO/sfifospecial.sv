`default_nettype none
module sfifospecial #(parameter DW = 8) ( // Just a circular buffer 
    input   wire logic i_clk,
    input   wire logic i_reset,

    // Write channel
    input   wire logic i_wr_en,
    input   wire logic [DW-1:0] i_wr_data,
    output  wire logic o_full,

    // Read side
    input   wire logic i_rd,
    output  logic [DW-1:0] o_rd_data,
    output  wire logic o_empty,
    // Error logic
    output   logic [4:0] read_ptr_o,
    output   logic [4:0] write_ptr_o
);

    reg [DW-1:0] fifo [0:15];
    reg [4:0] read_ptr = 0;
    reg [4:0] write_ptr = 0;
    assign read_ptr_o = read_ptr;
    assign write_ptr_o = write_ptr;
    initial begin
        for (integer i = 0; i < 16; i = i + 1) begin
            fifo[i] = 0;
        end
    end
    assign o_empty = (read_ptr == write_ptr);
    assign o_full = (write_ptr[4] != read_ptr[4]) & (read_ptr[3:0] == write_ptr[3:0]);
    assign o_rd_data = fifo[read_ptr[3:0]];
    // Logic to handle the pointers
    always_ff @(posedge i_clk) begin
        if (i_reset) begin
            read_ptr <= 0;
            write_ptr <= 0;
        end
        if (~i_reset & i_wr_en & ~o_full) begin
            write_ptr <= write_ptr + 1;
        end
        if (~i_reset & i_rd & ~o_empty) begin
            read_ptr <= read_ptr + 1;
        end
    end
    // Logic to handle memories
    always_ff @(posedge i_clk) begin
        if (~i_reset & i_wr_en & ~o_full) begin
            fifo[write_ptr[3:0]] <= i_wr_data;
        end
    end
endmodule : sfifospecial
