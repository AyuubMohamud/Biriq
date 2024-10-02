// Load Queue

// Works as this
/**
**/


module newLoadQueue #(parameter WOQE = 8, parameter MMIOE = 8) (
    input   wire logic                          core_clock_i,
    input   wire logic                          core_flush_i,

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
    output  wire logic [9:0]                    bram_rd_addr,
    input   wire logic [63:0]                   bram_rd_data_64,
    output  wire logic [23:0]                   load_cache_set_o,
    input   wire logic                          load_set_valid_i,
    input   wire logic                          load_set_i,
    output       logic                          dc_req,
    output       logic [31:0]                   dc_addr,
    output       logic [1:0]                    dc_op,
    output       logic                          dc_uncached,
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
    wire logic [5:0]  lsu_rob;
    wire logic [2:0]  lsu_op;
    wire logic [31:0] lsu_addr;
    wire logic [5:0]  lsu_dest;
    wire logic        lsu_vld;
    wire logic [31:0] conflict_data;
    wire logic [3:0]  conflict_bm;
    wire logic        conflict_resolvable;
    wire logic        conflict_res_valid;
    reg [23:0] current_miss;
    reg current_miss_valid = 0;
    skdbf #(.DW(85)) lqskidbuffer (core_clock_i, core_flush_i|rob_lock, busy, {lsu_rob,lsu_op,lsu_addr,lsu_dest,conflict_data, conflict_bm, conflict_resolvable,
    conflict_res_valid}, lsu_vld, lsu_busy_o, {lsu_rob_i,lsu_op_i,lsu_addr_i,lsu_dest_i, conflict_data_i, conflict_bm_i, conflict_resolvable_i, 
    conflict_res_valid_i}, lsu_vld_i);
    // Strongly ordered load queue, added here if unresolvable conflict on any region, if conflict and miss on a weakly ordered region, OR if MMIO
    wire so_enqueue = !core_flush_i&lsu_vld&!busy&((conflict_res_valid&!conflict_resolvable)|(conflict_res_valid&!lsu_addr[31]&!load_set_valid_i)|lsu_addr[31]);
    // Weakly ordered miss handling
    wire wk_enqueue = !core_flush_i&lsu_vld&!busy&!lsu_addr[31]&!conflict_res_valid&!load_set_valid_i&!(current_miss_valid&(lsu_addr[30:7]!=current_miss));
    wire wk_failed_enqueue = !core_flush_i&lsu_vld&!(wk_dequeue|so_dequeue|sfull|wfull)&!lsu_addr[31]&!conflict_res_valid&!load_set_valid_i&(current_miss_valid&(lsu_addr[30:7]!=current_miss));
    wire logic [5:0]  wlsu_rob;
    wire logic [2:0]  wlsu_op;
    wire logic [31:0] wlsu_addr;
    wire logic [5:0]  wlsu_dest;
    wire logic wempty;
    wire logic wfull;
    wire logic wk_dequeue = !current_miss_valid&!wempty&!rob_lock;
    sfifo2 #(.FW(WOQE), .DW(47)) weakQueue (core_clock_i, core_flush_i|rob_lock, wk_enqueue, {lsu_rob,lsu_op,lsu_addr,lsu_dest}, 
    wfull, wk_dequeue, {wlsu_rob,wlsu_op,wlsu_addr,wlsu_dest}, wempty);
    // Stronger ordered loads handling
    wire logic [5:0]  slsu_rob;
    wire logic [2:0]  slsu_op;
    wire logic [31:0] slsu_addr;
    wire logic [5:0]  slsu_dest;
    wire logic        slsu_slept;
    wire logic sempty;
    wire logic sfull;
    wire logic so_dequeue = dc_cmp&dc_uncached;
    sfifo2 #(.FW(MMIOE), .DW(48)) strongQueue (core_clock_i, core_flush_i|rob_lock, so_enqueue, {lsu_rob,lsu_op,lsu_addr,lsu_dest,conflict_res_valid}, 
    sfull, so_dequeue, {slsu_rob,slsu_op,slsu_addr,slsu_dest,slsu_slept}, sempty);
    assign busy = (wk_dequeue|so_dequeue|sfull|wfull|wk_failed_enqueue);
    always_ff @(posedge core_clock_i) begin
        if (!current_miss_valid&wk_enqueue&!rob_lock) begin
            current_miss_valid <= 1;
            current_miss <= lsu_addr[30:7];
        end else if (current_miss_valid) begin
            if (dc_cmp&!dc_uncached) begin
                current_miss_valid <= 0;
            end
        end
    end
    always_ff @(posedge core_clock_i) begin
        if (!sempty && (slsu_rob[4:0]==oldest_instruction_i) && !dc_req & !rob_lock && !(!store_buf_emp&slsu_slept) &!core_flush_i) begin
            dc_req <= 1;
            dc_addr <= slsu_addr;
            dc_op <= slsu_op[1:0];
            dc_uncached <= 1;
        end else if (current_miss_valid && !dc_req && !rob_lock &!core_flush_i) begin
            dc_req <= 1;
            dc_addr <= wlsu_addr;
            dc_op <= 0;
            dc_uncached <= 0;
        end else if (dc_req) begin
            if (dc_cmp) begin
                dc_req <= 1'b0;
            end
        end
    end

    assign load_cache_set_o = wk_dequeue ? wlsu_addr[30:7] : lsu_addr[30:7];
    wire [31:0] memdata;
    reg nx2_vd = 0;
    initial nx2_vd = 0;
    reg [1:0] nx2_addr; reg [31:0] nx2_io_data;
    reg [5:0] nx2_dest;
    reg [5:0] nx2_rob;
    reg [2:0] nx2_op;
    reg nx64sel = 0;
    reg [31:0] nx2_cdat; reg [3:0] nx2_bm; reg nx2_io;    
    always_ff @(posedge core_clock_i) begin
        nx2_vd <= core_flush_i ? 1'b0 : (wk_dequeue|so_dequeue)|(lsu_vld&!(wk_enqueue|so_enqueue)&!busy&!rob_lock);
        nx2_dest <= wk_dequeue ? wlsu_dest : so_dequeue ? slsu_dest : lsu_dest;
        nx2_rob <= wk_dequeue ? wlsu_rob : so_dequeue ? slsu_rob : lsu_rob;
        nx2_op <= wk_dequeue ? {wlsu_op} : so_dequeue ? {slsu_op} : {lsu_op};
        nx2_cdat <= conflict_data; nx2_bm <= conflict_bm&{4{!(wk_dequeue|so_dequeue)&(conflict_res_valid&conflict_resolvable)}};
        nx2_addr <= wk_dequeue ? wlsu_addr[1:0] : so_dequeue ? slsu_addr[1:0] : lsu_addr[1:0];
        nx2_io <= so_dequeue; nx2_io_data <= dc_data;
        nx64sel <= wk_dequeue ? wlsu_addr[2] : lsu_addr[2];
    end
    assign lsu_lock = dc_req|nx2_vd; // completion of i/o request
    assign bram_rd_en = 1; assign bram_rd_addr = {load_set_i, wk_dequeue ? wlsu_addr[11:3] : lsu_addr[11:3]};
    wire [31:0] data = nx2_io ? nx2_io_data : memdata;
    wire [31:0] bram_rd_data = nx64sel ? bram_rd_data_64[63:32] : bram_rd_data_64[31:0];
    wire [31:0] root_mem_data = {nx2_bm[3] ? nx2_cdat[31:24] : bram_rd_data[31:24], nx2_bm[2] ? nx2_cdat[23:16] : bram_rd_data[23:16],
    nx2_bm[1] ? nx2_cdat[15:8] : bram_rd_data[15:8], nx2_bm[0] ? nx2_cdat[7:0] : bram_rd_data[7:0]};
    assign memdata = nx2_op[1:0]==2'b10 ?  root_mem_data : nx2_op[1:0]==1 ? (nx2_addr[1] ? {16'h0000, root_mem_data[31:16]} :
    {16'h0000, root_mem_data[15:0]}) : nx2_addr[1:0]==2'b00 ? {24'h000000,root_mem_data[7:0]} : nx2_addr[1:0]==2'b01 ? {24'h000000,root_mem_data[15:8]} : nx2_addr[1:0]==2'b10 ? {24'h000000,root_mem_data[23:16]} :
    {24'h000000,root_mem_data[31:24]};
    assign ciff_o = (nx2_vd);

    assign lq_wr_en_o = nx2_vd&&(lq_wr_o!=0);

    assign lq_wr_data_o = ((nx2_op[2]||(nx2_op[1:0]==2'b10))) ? data : (nx2_op[0]) ? {{16{data[15]}},data[15:0]} : {{24{data[7]}},data[7:0]};
    assign lq_wr_o = nx2_dest;
    assign rob_o = nx2_rob;
endmodule
