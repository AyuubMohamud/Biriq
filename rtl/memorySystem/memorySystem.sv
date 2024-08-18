module memorySystem (
    input   wire logic                          cpu_clk_i,
    input   wire logic                          flush_i,

    // interface from renamer
    input   wire logic                          renamer_pkt_vld_i,
    input   wire logic [5:0]                    pkt0_rs1_i,
    input   wire logic [5:0]                    pkt0_rs2_i,
    input   wire logic [5:0]                    pkt0_dest_i,
    input   wire logic [31:0]                   pkt0_immediate_i,
    input   wire logic [4:0]                    pkt0_ios_type_i,
    input   wire logic [2:0]                    pkt0_ios_opcode_i,
    input   wire logic [4:0]                    pkt0_rob_i,
    input   wire logic                          pkt0_vld_i,
    input   wire logic [5:0]                    pkt1_rs1_i,
    input   wire logic [5:0]                    pkt1_rs2_i,
    input   wire logic [5:0]                    pkt1_dest_i,
    input   wire logic [31:0]                   pkt1_immediate_i,
    input   wire logic [4:0]                    pkt1_ios_type_i,
    input   wire logic [2:0]                    pkt1_ios_opcode_i,
    input   wire logic                          pkt1_vld_i,
    output  wire logic                          full,
    // prf
    input   wire logic [31:0]                   rs1_data,
    output  wire logic [5:0]                    rs1_o,
    input   wire logic [31:0]                   rs2_data,
    output  wire logic [5:0]                    rs2_o,
    // register ready status
    output  wire logic [5:0]                    r4_vec_indx_o,
    input   wire logic                          r4_i,
    output  wire logic [5:0]                    r5_vec_indx_o,
    input   wire logic                          r5_i,
    // csrfile inputs
    output  wire logic [31:0]                   tmu_data_o,
    output  wire logic [11:0]                   tmu_address_o,
    output  wire logic [1:0]                    tmu_opcode_o,
    output  wire logic                          tmu_wr_en,
    //  01 - CSRRW, 10 - CSRRS, 11 - CSRRC
    output  wire logic                          tmu_valid_o,
    input   wire logic                          tmu_done_i,
    input   wire logic                          tmu_excp_i,
    input   wire logic [31:0]                   tmu_data_i,
    // ROB LOCK > LSU LOCK ROB LOCK used to do exceptions // interrupts
    input   wire logic                          rob_lock,
    input   wire logic [4:0]                    rob_oldest_i,
    output  wire logic                          lsu_lock,

    output  wire logic [4:0]                    completed_rob_id,
    output  wire logic                          completion_valid,

    output  wire logic [4:0]                    lq_completed_rob_id,
    output  wire logic                          lq_completion_valid,

    output  wire logic                          exception_o,
    output  wire logic [3:0]                    exception_code_o,
    output  wire logic [5:0]                    exception_rob_o,
    output  wire logic [31:0]                   exception_addr_o,
    output  wire logic                          p2_we_i,
    output  wire logic [31:0]                   p2_we_data,
    output  wire logic [5:0]                    p2_we_dest,

    input   wire logic                          commit0, 
    input   wire logic                          commit1,
    output  wire logic                          stb_emp,
    // TileLink Bus Master Uncached Heavyweight
    output       logic [2:0]                    dcache_a_opcode,
    output       logic [2:0]                    dcache_a_param, // not needed
    output       logic [3:0]                    dcache_a_size,
    output       logic [31:0]                   dcache_a_address,
    output       logic [3:0]                    dcache_a_mask,  // not needed
    output       logic [31:0]                   dcache_a_data,  // not needed
    output       logic                          dcache_a_corrupt,  // not needed
    output       logic                          dcache_a_valid,
    input   wire logic                          dcache_a_ready, 

    input   wire logic [2:0]                    dcache_d_opcode,
    input   wire logic [1:0]                    dcache_d_param,
    input   wire logic [3:0]                    dcache_d_size,
    input   wire logic                          dcache_d_denied,
    input   wire logic [31:0]                   dcache_d_data,
    input   wire logic                          dcache_d_corrupt,
    input   wire logic                          dcache_d_valid,
    output  wire logic                          dcache_d_ready
);
    wire        lsu_busy;
    wire        lsu_vld;
    wire [5:0]  lsu_rob;
    wire [3:0]  lsu_op;
    wire [31:0] lsu_data;
    wire [31:0] lsu_addr;
    wire [5:0]  lsu_dest;
    wire        lq_full;
    wire [31:0] lq_addr;
    wire [2:0]  lq_ld_type;
    wire [5:0]  lq_dest;
    wire [5:0]  lq_rob;
    wire        lq_valid;
    wire            enqueue_full;
    wire  [29:0]    enqueue_address;
    wire  [31:0]    enqueue_data;
    wire  [3:0]     enqueue_bm;
    wire            enqueue_io;
    wire            enqueue_en;
    wire [4:0]      enqueue_rob;
    wire  [29:0]    conflict_address;
    wire  [3:0]     conflict_bm;
    wire [31:0] excp_pc;
    wire        excp_valid;
    wire [3:0]  excp_code;
    wire [5:0]  excp_rob;
    wire        ins_cmp;
    wire [4:0]  ins_rob;
    wire logic [4:0] agu_completed_rob_id;
    wire logic       agu_completion_valid;
    wire logic       agu_exception;
    wire logic [5:0] agu_exception_rob;
    wire logic [3:0] agu_exception_code;
    wire logic        conflict_resolvable;
    wire logic        conflict_res_valid;
    wire logic [31:0] conflict_data_c;
    wire logic [3:0]  conflict_bm_c;
    wire logic        cache_done;
    wire logic [29:0] store_address;
    wire logic [31:0] store_data;
    wire logic [3:0]  store_bm;
    wire logic        store_valid;
    wire store_buffer_empty;
    wire logic  [2:0]       opcode_i;
    wire logic  [31:0]      operand1_i;
    wire logic  [31:0]      operand2_i;
    wire logic              valid_i;
    wire logic              busy_o;
         logic  [31:0]      result_o;
         logic              wb_valid_o;
    wire memsched_we; wire [31:0] memsched_data; wire [5:0] memsched_dest;
    wire dcache_flush, dcache_resp;
    memory_scheduler port2 (cpu_clk_i, flush_i, renamer_pkt_vld_i, pkt0_rs1_i, pkt0_rs2_i, pkt0_dest_i, pkt0_immediate_i, pkt0_ios_type_i, pkt0_ios_opcode_i, 
    pkt0_rob_i, pkt0_vld_i, pkt1_rs1_i, pkt1_rs2_i, pkt1_dest_i, pkt1_immediate_i, pkt1_ios_type_i, pkt1_ios_opcode_i, pkt1_vld_i,full,rs1_data,rs1_o,rs2_data,rs2_o,
    r4_vec_indx_o,r4_i,r5_vec_indx_o,r5_i,lsu_busy,lsu_vld,lsu_rob,lsu_op,lsu_data,lsu_addr,
    lsu_dest, opcode_i,
    operand1_i,
    operand2_i,
    valid_i,
    busy_o,
    result_o,
    wb_valid_o,tmu_data_o,tmu_address_o,tmu_opcode_o,tmu_wr_en,tmu_valid_o,tmu_done_i,tmu_excp_i,
    tmu_data_i, store_buffer_empty, rob_lock, rob_oldest_i, agu_completed_rob_id, agu_completion_valid, agu_exception, agu_exception_rob,agu_exception_code, 
    memsched_we, memsched_data, memsched_dest,dcache_flush, dcache_resp);
    complex_unit cu0 (cpu_clk_i, flush_i, opcode_i,operand1_i,operand2_i,valid_i,busy_o,result_o,wb_valid_o);
    AGU0 agu (cpu_clk_i, flush_i, lsu_busy,lsu_vld,lsu_rob,lsu_op,lsu_data,lsu_addr,lsu_dest,
    lq_full,lq_addr,lq_ld_type,lq_dest,lq_rob,lq_valid,enqueue_full,enqueue_address,enqueue_data,enqueue_bm,enqueue_io,enqueue_en,enqueue_rob,conflict_address,conflict_bm,
    excp_pc,excp_valid,excp_code,excp_rob);

    storeBuffer #(.PHYS(32)) storeBuffer0 (cpu_clk_i, flush_i, enqueue_address,enqueue_data,enqueue_bm,enqueue_io, enqueue_en, enqueue_rob, enqueue_full, ins_rob, ins_cmp,commit0, commit1,
    conflict_address, conflict_bm, conflict_data_c,conflict_bm_c,conflict_resolvable,conflict_res_valid,cache_done,store_address,store_data,store_bm,store_valid,
    store_buffer_empty);
    wire        bram_rd_en;
    wire [10:0] bram_rd_addr;
    wire [31:0] bram_rd_data;
    wire [23:0] load_cache_set;
    wire        load_set_valid;
    wire        load_set;
    wire        dc_req;
    wire [31:0] dc_addr;
    wire [1:0]  dc_op;
    wire [31:0] dc_data;
    wire        dc_cmp;
    wire logic [5:0]  lq_wr;
    wire logic [31:0] lq_wr_data;
    wire logic        lq_wr_en;
    wire logic [5:0]  lq_rob_cmp;
    wire logic         lq_cmp;
    loadQueue lq (cpu_clk_i, flush_i, lq_valid, lq_rob, lq_ld_type, lq_addr, lq_dest, lq_full, conflict_data_c, conflict_bm_c, 
    conflict_resolvable, conflict_res_valid, bram_rd_en,bram_rd_addr,bram_rd_data,load_cache_set,load_set_valid,load_set,dc_req,dc_addr,dc_op,dc_data,
    dc_cmp, lq_wr,lq_wr_data,lq_wr_en,lq_rob_cmp,lq_cmp, rob_lock, lsu_lock, rob_oldest_i, store_buffer_empty);

    dcache datacache (cpu_clk_i, dcache_flush, dcache_resp,cache_done, store_address,store_data,store_bm,store_valid, dc_req,dc_addr,dc_op,dc_data,dc_cmp, bram_rd_en,
    bram_rd_addr,bram_rd_data,dcache_a_opcode,dcache_a_param,dcache_a_size,dcache_a_address,dcache_a_mask,dcache_a_data,dcache_a_corrupt,dcache_a_valid,
    dcache_a_ready,  dcache_d_opcode, dcache_d_param, dcache_d_size, dcache_d_denied, dcache_d_data, dcache_d_corrupt, dcache_d_valid, dcache_d_ready,
    load_cache_set,load_set_valid,load_set);
    assign p2_we_i = lq_wr_en|memsched_we; assign p2_we_dest = lq_wr_en ? lq_wr : memsched_dest; assign p2_we_data = lq_wr_en ? lq_wr_data : memsched_data;
    assign exception_o = agu_exception|excp_valid;
    assign exception_rob_o = agu_exception ? agu_exception_rob : excp_rob;
    assign exception_code_o = agu_exception ? agu_exception_code : excp_code;
    assign exception_addr_o = excp_pc;
    assign lq_completion_valid = lq_cmp|agu_completion_valid;
    assign lq_completed_rob_id = lq_cmp ? lq_rob_cmp[4:0] : agu_completed_rob_id[4:0];
    assign completion_valid = ins_cmp; 
    assign completed_rob_id = ins_rob; assign stb_emp = store_buffer_empty;
endmodule
