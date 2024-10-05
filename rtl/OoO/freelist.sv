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
//  | PARTICULAR PURPOSE. Please see the CERN-OHL-S v2 for applicable conditions.           |
//  |                                                                                       |
//  | Source location: https://github.com/AyuubMohamud/Biriq                                |
//  |                                                                                       |
//  | As per CERN-OHL-W v2 section 4, should You produce hardware based on this             |
//  | source, You must where practicable maintain the Source Location visible               |
//  | in the same manner as is done within this source.                                     |
//  |                                                                                       |
//  -----------------------------------------------------------------------------------------
module freelist (
    input   wire logic i_clk,
    // Write channel 0
    input   wire logic i_wr_en0,
    input   wire logic [5:0] i_wr_data0,
    output  wire logic o_full0,
    // Write channel 1
    input   wire logic i_wr_en1,
    input   wire logic [5:0] i_wr_data1,
    output  wire logic o_full1,
    // Read side 0
    input   wire logic i_rd0,
    output  logic [5:0] o_rd_data0,
    output  wire logic o_empty0,
    // Read side 1
    input   wire logic i_rd1,
    output  logic [5:0] o_rd_data1,
    output  wire logic o_empty1
);
    // Initialised by the RCU
    reg read_balance = 0;
    reg write_balance = 0;

    wire logic [5:0]    fifo0_i_wr_data     = write_balance ? i_wr_data1 : i_wr_en0 ? i_wr_data0 : i_wr_data1;
    wire logic          fifo0_o_full;
    wire logic          fifo0_i_wr_en       = !fifo0_o_full&&(write_balance ? (i_wr_en0&i_wr_en1) : (i_wr_en0|i_wr_en1));
    logic [5:0]         fifo0_o_rd_data;
    wire logic          fifo0_o_empty;
    wire logic          fifo0_i_rd          = !fifo0_o_empty&&(read_balance ? (i_rd0&i_rd1) : (i_rd0|i_rd1));
    wire logic [5:0]    fifo1_i_wr_data     = write_balance ? i_wr_en0 ? i_wr_data0 : i_wr_data1 : i_wr_data1;
    wire logic          fifo1_o_full;
    wire logic          fifo1_i_wr_en       = !fifo1_o_full&&(write_balance ? (i_wr_en0|i_wr_en1) : (i_wr_en0&i_wr_en1));
    logic [5:0]         fifo1_o_rd_data;
    wire logic          fifo1_o_empty;
    wire logic          fifo1_i_rd          = !fifo1_o_empty&&(read_balance ? (i_rd0|i_rd1) : (i_rd0&i_rd1));
    assign o_rd_data0 = read_balance ? fifo1_o_rd_data : fifo0_o_rd_data;
    assign o_rd_data1 = i_rd0 ? read_balance ? fifo0_o_rd_data : fifo1_o_rd_data : o_rd_data0;
    assign o_empty0 = fifo0_o_empty&fifo1_o_empty;
    assign o_empty1 = i_rd0 ? fifo0_o_empty|fifo1_o_empty : fifo0_o_empty&fifo1_o_empty;
    assign o_full0 = fifo0_o_full&fifo1_o_full;
    assign o_full1 = i_wr_en0 ? fifo0_o_full|fifo1_o_full : fifo0_o_full&fifo0_o_full;
    always_ff @(posedge i_clk) begin
        read_balance <= (i_rd0|i_rd1)&&!o_empty0 ? read_balance ? i_rd0&i_rd1 : i_rd0^i_rd1 : read_balance;
        write_balance <= (i_wr_en0|i_wr_en1)&&!o_full0 ? write_balance ? i_wr_en0&i_wr_en1 : i_wr_en0^i_wr_en1 : write_balance;
    end
    sfifoeven even (i_clk, 1'b0, fifo0_i_wr_en,fifo0_i_wr_data, fifo0_o_full,fifo0_i_rd, fifo0_o_rd_data, fifo0_o_empty);
    sfifoodd odd (i_clk, 1'b0, fifo1_i_wr_en,fifo1_i_wr_data, fifo1_o_full,fifo1_i_rd, fifo1_o_rd_data, fifo1_o_empty);
endmodule
