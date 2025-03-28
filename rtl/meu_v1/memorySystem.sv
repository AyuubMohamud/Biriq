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
module memorySystem #(
    parameter SB_ENTRIES = 8
) (
    input  wire        cpu_clk_i,
    input  wire        flush_i,
    input  wire        dcache_flush_i,
    output wire        dcache_flush_resp,
    // interface from renamer
    input  wire        renamer_pkt_vld_i,
    input  wire [ 5:0] pkt0_rs1_i,
    input  wire [ 5:0] pkt0_rs2_i,
    input  wire [ 5:0] pkt0_dest_i,
    input  wire [31:0] pkt0_immediate_i,
    input  wire [ 5:0] pkt0_ios_type_i,
    input  wire [ 2:0] pkt0_ios_opcode_i,
    input  wire [ 4:0] pkt0_rob_i,
    input  wire        pkt0_vld_i,
    input  wire [ 5:0] pkt1_rs1_i,
    input  wire [ 5:0] pkt1_rs2_i,
    input  wire [ 5:0] pkt1_dest_i,
    input  wire [31:0] pkt1_immediate_i,
    input  wire [ 5:0] pkt1_ios_type_i,
    input  wire [ 2:0] pkt1_ios_opcode_i,
    input  wire        pkt1_vld_i,
    output wire        full,
    // prf
    input  wire [31:0] rs1_data,
    output wire [ 5:0] rs1_o,
    input  wire [31:0] rs2_data,
    output wire [ 5:0] rs2_o,
    // register ready status
    output wire [ 5:0] r4_vec_indx_o,
    input  wire        r4_i,
    output wire [ 5:0] r5_vec_indx_o,
    input  wire        r5_i,
    // csrfile inputs
    output wire [31:0] tmu_data_o,
    output wire [11:0] tmu_address_o,
    output wire [ 1:0] tmu_opcode_o,
    output wire        tmu_wr_en,
    //  01 - CSRRW, 10 - CSRRS, 11 - CSRRC
    output wire        tmu_valid_o,
    input  wire        tmu_done_i,
    input  wire        tmu_excp_i,
    input  wire [31:0] tmu_data_i,
    // ROB LOCK > LSU LOCK ROB LOCK used to do exceptions // interrupts
    input  wire        rob_lock,
    input  wire [ 4:0] rob_oldest_i,
    output wire        lsu_lock,

    output wire [4:0] completed_rob_id,
    output wire       completion_valid,

    output wire [4:0] lq_completed_rob_id,
    output wire       lq_completion_valid,

    output wire        exception_o,
    output wire [ 3:0] exception_code_o,
    output wire [ 5:0] exception_rob_o,
    output wire [31:0] exception_addr_o,
    output wire        p2_we_i,
    output wire [31:0] p2_we_data,
    output wire [ 5:0] p2_we_dest,

    input  wire         commit0,
    input  wire         commit1,
    output wire         stb_emp,
    // TileLink Bus Master Uncached Heavyweight
    output logic [ 2:0] dcache_a_opcode,
    output logic [ 2:0] dcache_a_param,    // not needed
    output logic [ 3:0] dcache_a_size,
    output logic [31:0] dcache_a_address,
    output logic [ 3:0] dcache_a_mask,     // not needed
    output logic [31:0] dcache_a_data,     // not needed
    output logic        dcache_a_corrupt,  // not needed
    output logic        dcache_a_valid,
    input  wire         dcache_a_ready,

    input  wire [ 2:0] dcache_d_opcode,
    input  wire [ 1:0] dcache_d_param,
    input  wire [ 3:0] dcache_d_size,
    input  wire        dcache_d_denied,
    input  wire [31:0] dcache_d_data,
    input  wire        dcache_d_corrupt,
    input  wire        dcache_d_valid,
    output wire        dcache_d_ready,

    output wire [24:0] d_addr,
    output wire        d_write,
    input  wire        d_kill,
    input  wire        weak_io,
    input  wire        load_reordering
);

  wire         lq_full;
  wire  [31:0] lq_addr;
  wire  [ 2:0] lq_ld_type;
  wire  [ 5:0] lq_dest;
  wire  [ 5:0] lq_rob;
  wire         lq_cmo;
  wire         lq_valid;
  wire         enqueue_full;
  wire  [29:0] enqueue_address;
  wire  [31:0] enqueue_data;
  wire  [ 3:0] enqueue_bm;
  wire         enqueue_io;
  wire         enqueue_en;
  wire  [ 4:0] enqueue_rob;
  wire  [29:0] conflict_address;
  wire  [ 3:0] conflict_bm;
  wire  [31:0] excp_pc;
  wire         excp_valid;
  wire  [ 3:0] excp_code;
  wire  [ 5:0] excp_rob;
  wire         ins_cmp;
  wire  [ 4:0] ins_rob;
  wire  [ 4:0] agu_completed_rob_id;
  wire         agu_completion_valid;
  wire         agu_exception;
  wire  [ 5:0] agu_exception_rob;
  wire  [ 3:0] agu_exception_code;
  wire         conflict_resolvable;
  wire         conflict_res_valid;
  wire  [31:0] conflict_data_c;
  wire  [ 3:0] conflict_bm_c;
  wire         cache_done;
  wire  [29:0] store_address;
  wire  [31:0] store_data;
  wire  [ 3:0] store_bm;
  wire         store_valid;
  wire         store_buffer_empty;

  wire         lq_wr_en;


  wire         memsched_we;
  wire  [31:0] memsched_data;
  wire  [ 5:0] memsched_dest;
  wire  [ 3:0] bm;

  logic        meu_vld;
  logic [ 5:0] meu_rob;
  logic [ 5:0] meu_type;
  logic [ 2:0] meu_op;
  logic [31:0] meu_imm;
  logic [ 5:0] meu_rs1;
  logic [ 5:0] meu_rs2;
  logic [ 5:0] meu_dest;
  logic        meu_busy;
  memory_scheduler port2 (
      cpu_clk_i,
      flush_i,
      renamer_pkt_vld_i,
      pkt0_rs1_i,
      pkt0_rs2_i,
      pkt0_dest_i,
      pkt0_immediate_i,
      pkt0_ios_type_i,
      pkt0_ios_opcode_i,
      pkt0_rob_i,
      pkt0_vld_i,
      pkt1_rs1_i,
      pkt1_rs2_i,
      pkt1_dest_i,
      pkt1_immediate_i,
      pkt1_ios_type_i,
      pkt1_ios_opcode_i,
      pkt1_vld_i,
      full,
      r4_vec_indx_o,
      r4_i,
      r5_vec_indx_o,
      r5_i,
      meu_busy,
      meu_vld,
      meu_rob,
      meu_type,
      meu_op,
      meu_imm,
      meu_rs1,
      meu_rs2,
      meu_dest
  );
  wire         agu_busy;
  logic        agu_vld;
  logic [ 5:0] agu_rob;
  logic        agu_cmo;
  logic [ 3:0] agu_op;
  logic [31:0] agu_rs1;
  logic [31:0] agu_rs2;
  logic [31:0] agu_imm;
  logic [ 5:0] agu_dest;
  mem_rr rr0 (
      cpu_clk_i,
      flush_i,
      meu_busy,
      meu_vld,
      meu_rob,
      meu_type,
      meu_op,
      meu_imm,
      meu_rs1,
      meu_rs2,
      meu_dest,
      rs1_data,
      rs1_o,
      rs2_data,
      rs2_o,
      agu_busy,
      agu_vld,
      agu_rob,
      agu_cmo,
      agu_op,
      agu_rs1,
      agu_rs2,
      agu_imm,
      agu_dest,
      tmu_data_o,
      tmu_address_o,
      tmu_opcode_o,
      tmu_wr_en,
      tmu_valid_o,
      tmu_done_i,
      tmu_excp_i,
      tmu_data_i,
      store_buffer_empty,
      rob_lock,
      rob_oldest_i,
      agu_completed_rob_id,
      agu_completion_valid,
      agu_exception,
      agu_exception_rob,
      agu_exception_code,
      memsched_we,
      memsched_data,
      memsched_dest
  );
  wire         lsu_busy;
  logic        lsu_vld;
  logic [ 5:0] lsu_rob;
  logic        lsu_cmo;
  logic [ 3:0] lsu_op;
  logic [31:0] lsu_addr;
  logic [31:0] lsu_data;
  logic [ 5:0] lsu_dest;
  logic [31:0] lsu_sq_data;
  logic [ 3:0] lsu_sq_bm;
  AGU0 agu (
      cpu_clk_i,
      flush_i,
      agu_busy,
      agu_vld,
      agu_rob,
      agu_cmo,
      agu_op,
      agu_rs1,
      agu_rs2,
      agu_imm,
      agu_dest,
      lsu_busy,
      lsu_vld,
      lsu_rob,
      lsu_cmo,
      lsu_op,
      lsu_addr,
      lsu_data,
      lsu_dest,
      lsu_sq_data,
      lsu_sq_bm,
      excp_pc,
      excp_valid,
      excp_code,
      excp_rob,
      d_addr,
      d_write,
      d_kill
  );

  cacheAccess ca0 (
      lsu_busy,
      lsu_vld,
      lsu_rob,
      lsu_cmo,
      lsu_op,
      lsu_addr,
      lsu_data,
      lsu_dest,
      lsu_sq_data,
      lsu_sq_bm,
      lq_full,
      lq_addr,
      lq_cmo,
      lq_ld_type,
      lq_dest,
      lq_rob,
      bm,
      lq_valid,
      enqueue_full,
      enqueue_address,
      enqueue_data,
      enqueue_bm,
      enqueue_io,
      enqueue_en,
      enqueue_rob

  );
  wire sio;
  newStoreBuffer #(
      .PHYS(32),
      .ENTRIES(SB_ENTRIES)
  ) storeBuffer0 (
      cpu_clk_i,
      flush_i,
      enqueue_address,
      enqueue_data,
      enqueue_bm,
      enqueue_io,
      enqueue_en,
      enqueue_rob,
      enqueue_full,
      ins_rob,
      ins_cmp,
      commit0,
      commit1,
      conflict_address,
      conflict_bm,
      conflict_data_c,
      conflict_bm_c,
      conflict_resolvable,
      conflict_res_valid,
      cache_done,
      store_address,
      store_data,
      store_bm,
      sio,
      store_valid,
      store_buffer_empty
  );
  wire        bram_rd_en;
  wire [ 9:0] bram_rd_addr;
  wire [63:0] bram_rd_data;
  wire        collision;
  wire [24:0] load_cache_set;
  wire        load_set_valid;
  wire        load_set;
  wire        dc_req;
  wire [31:0] dc_addr;
  wire [ 1:0] dc_op;
  wire        dc_cmo;
  wire [31:0] dc_data;
  wire        dc_cmp;
  wire [ 5:0] lq_wr;
  wire [31:0] lq_wr_data;

  wire [ 5:0] lq_rob_cmp;
  wire        lq_cmp;
  wire        dcu;
  newLoadQueue lq (
      cpu_clk_i,
      flush_i,
      load_reordering,
      lq_valid,
      lq_rob,
      lq_cmo,
      lq_ld_type,
      lq_addr,
      bm,
      lq_dest,
      lq_full,
      conflict_data_c,
      conflict_bm_c,
      conflict_resolvable,
      conflict_res_valid,
      conflict_address,
      conflict_bm,
      bram_rd_en,
      bram_rd_addr,
      bram_rd_data,
      collision,
      load_cache_set,
      load_set_valid,
      load_set,
      dc_req,
      dc_addr,
      dc_op,
      dc_cmo,
      dcu,
      dc_data,
      dc_cmp,
      lq_wr,
      lq_wr_data,
      lq_wr_en,
      lq_rob_cmp,
      lq_cmp,
      rob_lock,
      lsu_lock,
      rob_oldest_i,
      store_buffer_empty,
      weak_io
  );

  dcache datacache (
      cpu_clk_i,
      dcache_flush_i,
      dcache_flush_resp,
      cache_done,
      store_address,
      store_data,
      store_bm,
      sio,
      store_valid,
      dc_req,
      dc_addr,
      dc_op,
      dc_cmo,
      dcu,
      dc_data,
      dc_cmp,
      bram_rd_en,
      bram_rd_addr,
      bram_rd_data,
      collision,
      dcache_a_opcode,
      dcache_a_param,
      dcache_a_size,
      dcache_a_address,
      dcache_a_mask,
      dcache_a_data,
      dcache_a_corrupt,
      dcache_a_valid,
      dcache_a_ready,
      dcache_d_opcode,
      dcache_d_param,
      dcache_d_size,
      dcache_d_denied,
      dcache_d_data,
      dcache_d_corrupt,
      dcache_d_valid,
      dcache_d_ready,
      load_cache_set,
      load_set_valid,
      load_set
  );
  assign p2_we_i = lq_wr_en | memsched_we;
  assign p2_we_dest = lq_wr_en ? lq_wr : memsched_dest;
  assign p2_we_data = lq_wr_en ? lq_wr_data : memsched_data;
  assign exception_o = agu_exception | excp_valid;
  assign exception_rob_o = agu_exception ? agu_exception_rob : excp_rob;
  assign exception_code_o = agu_exception ? agu_exception_code : excp_code;
  assign exception_addr_o = excp_pc;
  assign lq_completion_valid = lq_cmp | agu_completion_valid;
  assign lq_completed_rob_id = lq_cmp ? lq_rob_cmp[4:0] : agu_completed_rob_id[4:0];
  assign completion_valid = ins_cmp;
  assign completed_rob_id = ins_rob;
  assign stb_emp = store_buffer_empty;
endmodule
