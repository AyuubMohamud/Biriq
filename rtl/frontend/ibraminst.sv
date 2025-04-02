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
module ibraminst #(
    parameter  SIZE = 8192,
    localparam AW   = $clog2(SIZE) - 3
) (
    input  wire logic          clk,
    input  wire logic          rd_en,
    input  wire logic [AW-1:0] rd_addr,
    output logic      [  63:0] rd_data,
    input  wire logic          wr_en,
    input  wire logic [AW-1:0] wr_addr,
    input  wire logic [  63:0] wr_data
);
  reg [63:0] ram[0:(SIZE/8)-1];
  always_ff @(posedge clk) begin
    if (rd_en) begin
      rd_data <= ram[rd_addr];
    end
    if (wr_en) begin
      ram[wr_addr] <= wr_data;
    end
  end

endmodule
