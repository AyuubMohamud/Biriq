// Load Queue

// Works as this
/**
    Loads that hit in cache and whose conflicting data can be forwarded
    execute IMMEDIATELY regardless of any previous instructions as long as its
    not an I/O instruction or in deep sleep.
    Load misses/isIO/inDeepSleep -> out to FIFO
    So loads still execute out of order on this CPU
    USE FENCE.
    This way I avoid having another contrived data structure in the CPU (looking at you store queue/buffer).
**/


module loadQueue (
    input   wire logic                          cpu_clock_i,
    input   wire logic                          flush_i,

    input   wire logic                          lsu_vld_i,
    input   wire logic [5:0]                    lsu_rob_i,
    input   wire logic [2:0]                    lsu_op_i,
    input   wire logic [31:0]                   lsu_addr_i,
    input   wire logic [5:0]                    lsu_dest_i,
    output  wire logic                          lsu_busy_o,

    // store conflict interface
    input   wire logic [31:0]                   conflict_data_i,
    input   wire logic [3:0]                    conflict_bm_i,
    input   wire logic                          conflict_resolvable_i,
    input   wire logic                          conflict_res_valid_i,
    // sram
    output  wire logic                          bram_rd_en,
    output  wire logic [10:0]                   bram_rd_addr,
    input   wire logic [31:0]                   bram_rd_data,
    output  wire logic [23:0]                   load_cache_set_o,
    input   wire logic                          load_set_valid_i,
    input   wire logic                          load_set_i,
    output       logic                          dc_req,
    output       logic [31:0]                   dc_addr,
    output       logic [1:0]                    dc_op,
    input   wire logic [31:0]                   dc_data,
    input   wire logic                          dc_cmp,
    // register file
    output  wire logic [5:0]                    lq_wr_o,
    output  wire logic [31:0]                   lq_wr_data_o,
    output  wire logic                          lq_wr_en_o,
    output  wire logic [5:0]                    rob_o,
    output  wire logic                          ciff_o,
    input   wire logic                          rob_lock,
    output  wire logic                          lsu_lock,
    input   wire logic [4:0]                    oldest_instruction_i,
    input   wire logic                          store_buf_emp
);
    wire busy;
    wire this_cycle_from_lsu;
    wire logic [5:0]  lsu_rob;
    wire logic [2:0]  lsu_op;
    wire logic [31:0] lsu_addr;
    wire logic [5:0]  lsu_dest;
    wire logic        lsu_vld;
    wire logic [31:0] conflict_data;
    wire logic [3:0]  conflict_bm;
    wire logic        conflict_resolvable;
    wire logic        conflict_res_valid;
    skdbf #(.DW(85)) lqskidbuffer (cpu_clock_i, flush_i|rob_lock, busy, {lsu_rob,lsu_op,lsu_addr,lsu_dest,conflict_data, conflict_bm, conflict_resolvable,
    conflict_res_valid}, lsu_vld, lsu_busy_o, {lsu_rob_i,lsu_op_i,lsu_addr_i,lsu_dest_i, conflict_data_i, conflict_bm_i, conflict_resolvable_i, 
    conflict_res_valid_i}, lsu_vld_i);
    // Missed Load Queue
    wire current_req_miss = lsu_vld&!busy&((conflict_res_valid&!conflict_resolvable)|lsu_addr[31]|!load_set_valid_i|!this_cycle_from_lsu);
    wire buffer_full; wire miss_satisfied; wire empty;
    wire logic [5:0]  mlsu_rob;
    wire logic [2:0]  mlsu_op;
    wire logic [31:0] mlsu_addr;
    wire logic [5:0]  mlsu_dest;
    assign busy = buffer_full;
    assign load_cache_set_o = this_cycle_from_lsu ? lsu_addr[30:7] : mlsu_addr[30:7];
    sfifo2 #(.FW(4), .DW(47)) missedMemLoads (cpu_clock_i, flush_i|rob_lock, current_req_miss, {lsu_rob,lsu_op,lsu_addr,lsu_dest}, 
    buffer_full, miss_satisfied, {mlsu_rob,mlsu_op,mlsu_addr,mlsu_dest}, empty);
    assign this_cycle_from_lsu = !dc_cmp;
    wire [31:0] memdata;
    reg nx2_vd = 0;
    initial nx2_vd = 0;
    reg [1:0] nx2_addr; reg [31:0] nx2_io_data;
    reg [5:0] nx2_dest;
    reg [5:0] nx2_rob;
    reg [2:0] nx2_op;
    reg [31:0] nx2_cdat; reg [3:0] nx2_bm; reg nx2_io;
    assign lsu_lock = dc_req|nx2_vd; // completion of i/o request
    assign lq_wr_en_o = nx2_vd&&(lq_wr_o!=0);
    wire [31:0] data = nx2_io ? nx2_io_data : memdata;
    assign lq_wr_data_o = ((nx2_op[2]||(nx2_op[1:0]==2'b10))) ? data : (nx2_op[0]) ? {{16{data[15]}},data[15:0]} : {{24{data[7]}},data[7:0]};
    assign lq_wr_o = nx2_dest;
    assign rob_o = nx2_rob;
    assign miss_satisfied = dc_cmp;
    always_ff @(posedge cpu_clock_i) begin
        if (!empty && (mlsu_rob[4:0]==oldest_instruction_i) && !dc_req & !rob_lock && store_buf_emp) begin
            dc_req <= 1;
            dc_addr <= mlsu_addr;
            dc_op <= mlsu_op[1:0];
        end else if (dc_req) begin
            if (dc_cmp) begin
                dc_req <= 1'b0;
            end
        end
    end
    assign bram_rd_en = 1; assign bram_rd_addr = {load_set_i, this_cycle_from_lsu ? lsu_addr[11:2] : mlsu_addr[11:2]};
    wire [31:0] root_mem_data = {nx2_bm[3] ? nx2_cdat[31:24] : bram_rd_data[31:24], nx2_bm[2] ? nx2_cdat[23:16] : bram_rd_data[23:16],
    nx2_bm[1] ? nx2_cdat[15:8] : bram_rd_data[15:8], nx2_bm[0] ? nx2_cdat[7:0] : bram_rd_data[7:0]};
    assign memdata = nx2_op[1:0]==2'b10 ?  root_mem_data : nx2_op[1:0]==1 ? (nx2_addr[1] ? {16'h0000, root_mem_data[31:16]} :
    {16'h0000, root_mem_data[15:0]}) : nx2_addr[1:0]==2'b00 ? {24'h000000,root_mem_data[7:0]} : nx2_addr[1:0]==2'b01 ? {24'h000000,root_mem_data[15:8]} : nx2_addr[1:0]==2'b10 ? {24'h000000,root_mem_data[23:16]} :
    {24'h000000,root_mem_data[31:24]};
    assign ciff_o = (nx2_vd);
    always_ff @(posedge cpu_clock_i) begin
        nx2_vd <= flush_i ? 1'b0 : (dc_cmp)|(lsu_vld&this_cycle_from_lsu&!busy&!rob_lock&!current_req_miss);
        nx2_dest <= dc_cmp ? mlsu_dest : lsu_dest;
        nx2_rob <= dc_cmp ? mlsu_rob : lsu_rob;
        nx2_op <= dc_cmp ? {mlsu_op[2:0]} : {lsu_op[2:0]};
        nx2_cdat <= conflict_data; nx2_bm <= conflict_bm&{4{!dc_cmp&(conflict_res_valid&conflict_resolvable)}};
        nx2_addr <= this_cycle_from_lsu ? lsu_addr[1:0] : mlsu_addr[1:0];
        nx2_io <= dc_cmp&dc_addr[31]; nx2_io_data <= dc_data;
    end


endmodule
