module dcache (
    input   wire logic                          cpu_clock_i,
    input   wire logic                          dcache_flush_i,
    output  wire logic                          dcache_idle_o,
    // Cache interface
    output  wire logic                          cache_done,
    input   wire logic [29:0]                   store_address_i,
    input   wire logic [31:0]                   store_data_i,
    input   wire logic [3:0]                    store_bm_i,
    input   wire logic                          store_valid_i,

    // cache request
    input    wire logic                         dc_req,
    input    wire logic [31:0]                  dc_addr,
    input    wire logic [1:0]                   dc_op,
    output        logic [31:0]                  dc_data,
    output   wire logic                         dc_cmp,
    // sram
    input   wire logic                          bram_rd_en,
    input   wire logic [10:0]                   bram_rd_addr,
    output  wire logic [31:0]                   bram_rd_data,
    
    // TileLink Bus Master Uncached Heavyweight
    output       logic [2:0]                    dcache_a_opcode,
    output       logic [2:0]                    dcache_a_param,
    output       logic [3:0]                    dcache_a_size,
    output       logic [31:0]                   dcache_a_address,
    output       logic [3:0]                    dcache_a_mask,
    output       logic [31:0]                   dcache_a_data,
    output       logic                          dcache_a_corrupt,
    output       logic                          dcache_a_valid,
    input   wire logic                          dcache_a_ready, 
    /* verilator lint_off UNUSEDSIGNAL */
    input   wire logic [2:0]                    dcache_d_opcode,
    input   wire logic [1:0]                    dcache_d_param,
    input   wire logic [3:0]                    dcache_d_size,
    input   wire logic                          dcache_d_denied,
    /* verilator lint_on UNUSEDSIGNAL */
    input   wire logic [31:0]                   dcache_d_data,
    /* verilator lint_off UNUSEDSIGNAL */
    input   wire logic                          dcache_d_corrupt,
    /* verilator lint_on UNUSEDSIGNAL */
    input   wire logic                          dcache_d_valid,
    output  wire logic                          dcache_d_ready,

    // cache tags
    input   wire logic [23:0]                   load_cache_set_i,
    output  wire logic                          load_set_valid_o,
    output  wire logic                          load_set_o
);
    reg [18:0] tags0 [0:31]; reg [18:0] tags1 [0:31];// from addr[31:0], addr[31:12] is extracted, and addr[12:7] used for index, addr[6:0] is offset
    reg valid0 [0:31];reg valid1 [0:31]; reg [1:0] rr= 2'b01;
    wire [1:0] replacement_bitvec; wire replacement_enc;
    initial begin
        for (integer x = 0; x < 32; x++) begin
            tags0[x] = 0;tags1[x] = 0;
        end
        for (integer x = 0; x < 32; x++) begin
            valid0[x] = 0;valid1[x] = 0;
        end
    end
    wire [3:0] wr_en; wire [10:0] wr_addr; wire [31:0] wr_data; 
    wire [1:0] match; wire match_line;
    assign match = {tags1[store_address_i[9:5]]==store_address_i[28:10], tags0[store_address_i[9:5]]==store_address_i[28:10]} &
    {valid1[store_address_i[9:5]], valid0[store_address_i[9:5]]};
    assign match_line = match[1];
    dbraminst dsram (cpu_clock_i, bram_rd_en, bram_rd_addr, bram_rd_data, wr_en, wr_addr, wr_data);
    localparam IDLE = 3'b000; localparam INIT_LOAD = 3'b001; localparam LOAD_CMP = 3'b010; localparam STORE_INIT = 3'b100; localparam STORE_CMP = 3'b101;
    localparam DFLUSH = 3'b111;
    reg [2:0] cache_fsm = IDLE;
    assign dcache_idle_o = cache_fsm==IDLE;
    reg [4:0] counter = 0; localparam IO_LD_CMP = 3'b011; localparam MEM_LD_CMP = 3'b110;
    wire cache_fill = (cache_fsm==LOAD_CMP)&(dcache_d_valid)&(!dc_addr[31]);
    assign wr_en = {cache_fill|((|match)&(cache_fsm==STORE_CMP)&store_bm_i[3]), cache_fill
    |((|match)&(cache_fsm==STORE_CMP)&store_bm_i[2]), cache_fill|((|match)&(cache_fsm==STORE_CMP)&store_bm_i[1]), 
    cache_fill|((|match)&(cache_fsm==STORE_CMP)&store_bm_i[0])};
    wire [1:0] ld_vld = {valid1[load_cache_set_i[4:0]], valid0[load_cache_set_i[4:0]]};
    wire [1:0] ld_mtch = {tags1[load_cache_set_i[4:0]]==load_cache_set_i[23:5], tags0[load_cache_set_i[4:0]]==load_cache_set_i[23:5]} &
    ld_vld;
    assign load_set_o = ld_mtch[1];
    assign load_set_valid_o = |ld_mtch;
    assign replacement_bitvec = &ld_vld ? rr : ld_vld==2'b00 ? 2'b01 : ld_vld==2'b01 ? 2'b10 : 2'b01;
    assign replacement_enc = replacement_bitvec[1];
    assign wr_addr = cache_fsm==LOAD_CMP ? {replacement_enc, dc_addr[11:7], counter} : {match_line, store_address_i[9:0]};
    assign wr_data = cache_fsm==LOAD_CMP ? dcache_d_data : store_data_i;
    assign dc_cmp = (dc_addr[31]&(cache_fsm==IO_LD_CMP))|((cache_fsm==MEM_LD_CMP));
    assign cache_done = cache_fsm==STORE_CMP && dcache_d_valid; assign dcache_d_ready = 1'b1;

    logic [1:0] recover_low_order; logic [1:0] op; logic [31:0] recovered_data;
    initial dcache_a_valid = 0;
    always_comb begin
        case (store_bm_i[3:0])
            4'b0001: begin
                recover_low_order = 2'b00;
                op = 2'b00;
                recovered_data = store_data_i;
            end
            4'b0010: begin
                recover_low_order = 2'b01;
                op = 2'b00;
                recovered_data = {24'h000000, store_data_i[15:8]};
            end
            4'b0011: begin
                recover_low_order = 2'b00;
                op = 2'b01; recovered_data = store_data_i;
            end
            4'b0100: begin
                recover_low_order = 2'b10;
                op = 2'b00; recovered_data = {24'h000000, store_data_i[23:16]};
            end
            4'b1100: begin
                recover_low_order = 2'b10;
                op = 2'b01; recovered_data = {16'h0000, store_data_i[31:16]};
            end
            4'b1000: begin
                recover_low_order = 2'b11;
                op = 2'b00; recovered_data = {24'h000000, store_data_i[31:24]};
            end
            4'b1111: begin
                recover_low_order = 2'b00;
                op = 2'b10; recovered_data = store_data_i;
            end
            default: begin
                recover_low_order = 0; op = 0; recovered_data = store_data_i;
            end
        endcase
    end

    always_ff @(posedge cpu_clock_i) begin  
        case (cache_fsm)
            IDLE: begin
                rr <= {rr[0],rr[1]};
                if (dcache_flush_i) begin
                    cache_fsm <= DFLUSH;
                end
                else if (store_valid_i) begin
                    cache_fsm <= STORE_INIT;
                end else if (dc_req) begin
                    cache_fsm <= INIT_LOAD;
                end
            end 
            INIT_LOAD: begin
                rr <= {rr[0],rr[1]};
                dcache_a_address <= dc_addr[31] ? dc_addr : {dc_addr[31:7],7'h00}; dcache_a_mask <= 0; dcache_a_param <= 0;
                dcache_a_corrupt <= 0;
                dcache_a_opcode <= 3'd4; dcache_a_size <= dc_addr[31] ? {2'b00,dc_op} : 4'd7; dcache_a_valid <= 1;
                cache_fsm <= LOAD_CMP;
            end
            LOAD_CMP: begin
                dcache_a_valid <= dcache_a_ready ? 1'b0 : dcache_a_valid;
                if (dc_addr[31]&dcache_d_valid) begin
                    cache_fsm <= IO_LD_CMP;
                    dc_data <= dcache_d_data;
                end
                if (!dc_addr[31]&dcache_d_valid) begin
                    if (counter==5'd31) begin
                        counter <= 0;
                        cache_fsm <= MEM_LD_CMP;
                        tags0[dc_addr[11:7]] <= replacement_bitvec[0] ? dc_addr[30:12] : tags0[dc_addr[11:7]];
                        tags1[dc_addr[11:7]] <= replacement_bitvec[1] ? dc_addr[30:12] : tags1[dc_addr[11:7]];
                        valid0[dc_addr[11:7]] <= replacement_bitvec[0] ? 1'b1 : valid0[dc_addr[11:7]];
                        valid1[dc_addr[11:7]] <= replacement_bitvec[1] ? 1'b1 : valid1[dc_addr[11:7]];
                    end else begin
                        counter <= counter + 1'b1;
                    end
                end
            end
            MEM_LD_CMP: begin
                rr <= {rr[0],rr[1]};
                cache_fsm <= IDLE;
            end
            STORE_INIT: begin
                rr <= {rr[0],rr[1]};
                dcache_a_address <= {store_address_i, recover_low_order};
                dcache_a_opcode <= 3'd0; dcache_a_size <= {2'b00,op}; dcache_a_valid <= 1;
                dcache_a_data <= recovered_data; dcache_a_mask <= 4'hF;
                cache_fsm <= STORE_CMP;
            end
            STORE_CMP: begin
                rr <= {rr[0],rr[1]};
                dcache_a_valid <= dcache_a_ready ? 1'b0 : dcache_a_valid;
                if (dcache_d_valid) begin
                    cache_fsm <= IDLE;
                end
            end
            IO_LD_CMP: begin
                rr <= {rr[0],rr[1]};
                cache_fsm <= IDLE;
            end
            DFLUSH: begin
                rr <= {rr[0],rr[1]};
                counter <= counter + 1;                    
                valid0[counter] <= 1'b0;
                valid1[counter] <= 1'b0;
                if (counter==5'b11111) begin
                    cache_fsm <= IDLE;
                end
            end
            default: begin
                
            end 
        endcase
    end

endmodule
