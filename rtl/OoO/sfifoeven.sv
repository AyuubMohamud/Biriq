// SPDX-FileCopyrightText: 2024 Ayuub Mohamud <ayuub.mohamud@outlook.com>
// SPDX-License-Identifier: CERN-OHL-W-2.0

//  -----------------------------------------------------------------------------------------
//  | Copyright (C) Ayuub Mohamud 2024.                                                     |
//  |                                                                                       |
//  | This source describes Open Hardware (RTL) and is licensed under the CERN-OHL-W v2.    |
//  |                                                                                       |
//  | You may redistribute and modify this source and make products using it under          |
//  | the terms of the CERN-OHL-W v2 (https://ohwr.org/cern_ohl_w_v2.txt).                  |
//  |                                                                                       |
//  | This source is distributed WITHOUT ANY EXPRESS OR IMPLIED WARRANTY,                   |
//  | INCLUDING OF MERCHANTABILITY, SATISFACTORY QUALITY AND FITNESS FOR A                  |
//  | PARTICULAR PURPOSE. Please see the CERN-OHL-W v2 for applicable conditions.           |
//  |                                                                                       |
//  | Source location: https://github.com/AyuubMohamud/Biriq                                |
//  |                                                                                       |
//  | As per CERN-OHL-W v2 section 4, should You produce hardware based on this             |
//  | source, You must where practicable maintain the Source Location visible               |
//  | in the same manner as is done within this source.                                     |
//  |                                                                                       |
//  -----------------------------------------------------------------------------------------

`default_nettype none
module sfifoeven ( // Just a circular buffer 
    input   wire logic i_clk,
    input   wire logic i_reset,

    // Write channel
    input   wire logic i_wr_en,
    input   wire logic [5:0] i_wr_data,
    output  wire logic o_full,

    // Read side
    input   wire logic i_rd,
    output  logic [5:0] o_rd_data,
    output  wire logic o_empty
);

    reg [5:0] fifo [0:31];
    reg [5:0] read_ptr = 0;
    reg [5:0] write_ptr = 16;

    initial begin
        for (integer i = 0; i < 16; i = i + 1) begin
            fifo[i] = 32+(i*2);
        end
    end
    assign o_empty = (read_ptr == write_ptr);
    assign o_full = (write_ptr[5] != read_ptr[5]) & (read_ptr[4:0] == write_ptr[4:0]);
    assign o_rd_data = fifo[read_ptr[4:0]];
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
            fifo[write_ptr[4:0]] <= i_wr_data;
        end
    end


`ifdef FORMAL
    reg p_valid;
    initial p_valid = 0;
    initial assume(!i_wr_en);
    initial assume(!i_rd);
    initial assume(!i_resetn);
    initial assume(write_ptr == 0);
    initial assume(read_ptr == 0);

    always @* begin
        assert(o_empty == (write_ptr-read_ptr == 0));
        assert(o_full == ((write_ptr[5] != read_ptr[5]) & (read_ptr[4:0] == write_ptr[4:0])) );
    end

    always @(posedge i_clk) begin
        p_valid <= 1;
    end

    always @(posedge i_clk) begin
        if ($past(i_wr_en) & $past(i_resetn) & $past(o_full) & p_valid) begin
            assert(overflow);
        end
        if ($past(i_rd) & $past(o_empty) & $past(i_resetn) & p_valid) begin
            assert(underflow);
        end
    end

    always @(posedge i_clk) begin
        if ($past(i_resetn) & $past(~o_full) & $past(i_wr_en) & p_valid) begin
            assert(write_ptr == ($past(write_ptr) + 1'b1));
        end
        if ($past(i_resetn) & $past(~o_empty) & $past(i_rd) & p_valid) begin
            assert(read_ptr == ($past(read_ptr) + 1'b1));
        end
        if ($past(i_resetn) & $past(o_full) & p_valid) begin
            assert($stable(write_ptr));
        end
        if ($past(i_resetn) & $past(o_empty) & p_valid) begin
            assert($stable(read_ptr));
        end
    end

    always @(posedge i_clk) begin
        if ($past(i_resetn) & ~($past(o_full)) & $past(i_wr_en) & p_valid) begin
            assert(fifo[$past(write_ptr[4:0])] == $past(i_wr_data));
        end
        if ($past(i_resetn) & $past(~o_empty) & $past(i_rd) & p_valid) begin
            assert(o_rd_data == fifo[$past(read_ptr[4:0])]);
        end
    end

`endif

endmodule : sfifoeven
