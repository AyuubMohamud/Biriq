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
module sfifo2 #(parameter FW = 32, parameter DW = 47) ( // Just a circular buffer 
    input   wire logic i_clk,
    input   wire logic i_reset,

    // Write channel
    input   wire logic i_wr_en,
    input   wire logic [DW-1:0] i_wr_data,
    output  wire logic o_full,

    // Read side
    input   wire logic i_rd,
    output  logic [DW-1:0] o_rd_data,
    output  wire logic o_empty
);

    reg [DW-1:0] fifo [0:FW-1];
    reg [$clog2(FW):0] read_ptr = 0;
    reg [$clog2(FW):0] write_ptr = 0;

    initial begin
        for (integer i = 0; i < FW; i = i + 1) begin
            fifo[i] = 0;
        end
    end
    assign o_empty = (read_ptr == write_ptr);
    assign o_full = (write_ptr[$clog2(FW)] != read_ptr[$clog2(FW)]) & (read_ptr[$clog2(FW)-1:0] == write_ptr[$clog2(FW)-1:0]);
    assign o_rd_data = fifo[read_ptr[$clog2(FW)-1:0]];
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
            fifo[write_ptr[$clog2(FW)-1:0]] <= i_wr_data;
        end
    end
endmodule
