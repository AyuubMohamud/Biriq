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
module newStoreBuffer #(
    parameter PHYS = 32,
    parameter ENTRIES = 10
) (
    input  wire             cpu_clk_i,
    input  wire             flush_i,
    // enqueue
    input  wire  [PHYS-3:0] enqueue_address_i,
    input  wire  [    31:0] enqueue_data_i,
    input  wire  [     3:0] enqueue_bm_i,
    input  wire             enqueue_io_i,
    input  wire             enqueue_en_i,
    input  wire  [     4:0] enqueue_rob_i,
    output wire             enqueue_full_o,
    // rcu
    output wire  [     4:0] complete,
    output wire             complete_vld,
    // make non spec (ROB)
    input  wire             commit0,
    input  wire             commit1,
    // store conflict interface
    input  wire  [PHYS-3:0] conflict_address_i,
    input  wire  [     3:0] conflict_bm_i,
    output wire  [    31:0] conflict_data_o,
    output wire  [     3:0] conflict_bm_o,
    output wire             conflict_resolvable_o,
    output wire             conflict_res_valid_o,
    input  wire             cache_done,
    output logic [PHYS-3:0] store_address_o,
    output logic [    31:0] store_data_o,
    output logic [     3:0] store_bm_o,
    output logic            store_io_o,
    output logic            store_valid_o,
    output logic            no_nonspec
);
  reg [PHYS-3:0] physical_addresses[0:ENTRIES-1];
  reg [31:0] data[0:ENTRIES-1];
  reg [3:0] bitmask[0:ENTRIES-1];
  reg [ENTRIES-1:0] io;
  reg [ENTRIES-1:0] speculative;
  reg [ENTRIES-1:0] vld = 0;

  wire enqueue_full = &vld;
  assign enqueue_full_o = enqueue_full;
  // conflict resolver
  logic [31:0] conflict_dq_id;
  logic [ENTRIES-1:0] conflicts;
  wire onehot;
  genOneHot #(ENTRIES) onehotgen (
      conflicts,
      onehot
  );
  logic [3:0] conflict_bitmask;
  logic conflict_io;
  assign conflict_resolvable_o = onehot & !conflict_io;
  assign conflict_data_o = conflict_dq_id;
  assign conflict_bm_o = conflict_bitmask;
  assign conflict_res_valid_o = |conflicts;
  for (genvar i = 0; i < ENTRIES; i++) begin : _comparison
    assign conflicts[i] = (physical_addresses[i]==conflict_address_i)&&|(bitmask[i]&conflict_bm_i)&&vld[i];
  end
  logic FINISHSEL;
  always_comb begin
    FINISHSEL = '0;
    conflict_dq_id = 'x;
    conflict_io = 'x;
    conflict_bitmask = 'x;
    for (integer i = 0; i < ENTRIES; i++) begin
      if (conflicts[i] & !FINISHSEL) begin
        conflict_dq_id = data[i];
        conflict_bitmask = bitmask[i];
        conflict_io = io[i];
      end
    end
  end

  wire [ENTRIES-1:0] shift;
  wire [ENTRIES-1:0] spec;
  for (genvar i = 0; i < ENTRIES; i++) begin : shift_logic
    assign shift[i] = !(&vld[i:0]);
  end

  logic [ENTRIES-1:0] ddec;
  logic [ENTRIES-1:0] vldl;
  logic FINISHSEL2;
  always_comb begin
    FINISHSEL2 = '0;
    ddec = '0;
    for (integer i = 0; i < ENTRIES; i++) begin
      if (vld[i] & speculative[i] & !FINISHSEL2) begin
        FINISHSEL2 = 1;
        ddec[i] = 1;
      end
    end
  end

  logic [ENTRIES-1:0] ddec2;
  logic FINISHSEL3;
  always_comb begin
    FINISHSEL3 = '0;
    ddec2 = '0;
    for (integer i = 0; i < ENTRIES; i++) begin
      if (vld[i] & speculative[i] & !ddec[i] & !FINISHSEL3) begin
        FINISHSEL3 = 1;
        ddec2[i]   = 1;
      end
    end
  end
  logic [ENTRIES-1:0] cdec;
  logic [31:0] cache_dq;
  logic [PHYS-3:0] address;
  logic [3:0] bm;
  logic c_io;
  logic FINISHSEL4;
  always_comb begin
    FINISHSEL4 = '0;
    cdec = '0;
    cache_dq = 'x;
    address = 'x;
    bm = 'x;
    c_io = 'x;
    for (
        integer i = 0; i < ENTRIES; i++
    ) begin  // Change store buffer to stop at earliest valid entry regardless of if it is speculative or not
      if (vld[i] & !FINISHSEL4) begin
        FINISHSEL4 = 1;
        cdec[i] = ~speculative[i];
        cache_dq = data[i];
        address = physical_addresses[i];
        bm = bitmask[i];
        c_io = io[i];
      end
    end
  end
  always_ff @(posedge cpu_clk_i) begin
    physical_addresses[ENTRIES-1] <= shift[ENTRIES-1] ? enqueue_address_i : physical_addresses[ENTRIES-1];
    bitmask[ENTRIES-1] <= shift[ENTRIES-1] ? enqueue_bm_i : bitmask[ENTRIES-1];
    data[ENTRIES-1] <= shift[ENTRIES-1] ? enqueue_data_i : data[ENTRIES-1];
    io[ENTRIES-1] <= shift[ENTRIES-1] ? enqueue_io_i : io[ENTRIES-1];
    vld[ENTRIES-1] <= shift[ENTRIES-1] ? !flush_i & enqueue_en_i : vldl[ENTRIES-1];
    speculative[ENTRIES-1] <= shift[ENTRIES-1] ? 1'b1 : spec[ENTRIES-1];
  end

  for (genvar i = 0; i < ENTRIES; i++) begin : _spec
    assign spec[i] = speculative[i]&!(ddec[i]&(commit0|commit1))&!(ddec2[i]&(commit0&commit1));
  end
  for (genvar i = 0; i < ENTRIES; i++) begin : _valid
    assign vldl[i] = vld[i] & (spec[i] ? !flush_i : !(cdec[i] & cache_done));
  end
  for (genvar i = ENTRIES - 1; i > 0; i--) begin : _shift
    always_ff @(posedge cpu_clk_i) begin
      physical_addresses[i-1] <= shift[i-1] ? physical_addresses[i] : physical_addresses[i-1];
      bitmask[i-1] <= shift[i-1] ? bitmask[i] : bitmask[i-1];
      data[i-1] <= shift[i-1] ? data[i] : data[i-1];
      io[i-1] <= shift[i-1] ? io[i] : io[i-1];
      speculative[i-1] <= shift[i-1] ? spec[i] : spec[i-1];
      vld[i-1] <= shift[i-1] ? vldl[i] : vldl[i-1];
    end
  end

  assign store_valid_o = (|cdec);
  assign store_data_o = cache_dq;
  assign store_bm_o = bm;
  assign store_address_o = address;
  assign store_io_o = c_io;
  assign no_nonspec = !(|((~speculative)&vld));// inner expression 1 when there are valid instructions that are not speculative, since the other modules use
  // store buffer empty, store buffer empty is high when inner expression is 0
  assign complete_vld = enqueue_en_i & !enqueue_full;
  assign complete = enqueue_rob_i;
endmodule
