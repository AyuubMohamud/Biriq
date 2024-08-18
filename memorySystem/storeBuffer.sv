module storeBuffer #(parameter PHYS = 32) (
    input   wire logic                      cpu_clk_i,
    input   wire logic                      flush_i,
    // enqueue
    input   wire logic [PHYS-3:0]           enqueue_address_i,
    input   wire logic [31:0]               enqueue_data_i,
    input   wire logic [3:0]                enqueue_bm_i,
    input   wire logic                      enqueue_io_i,
    input   wire logic                      enqueue_en_i,
    input   wire logic [4:0]                enqueue_rob_i,
    output  wire logic                      enqueue_full_o,
    // rcu
    output  wire logic [4:0]                complete,
    output  wire logic                      complete_vld,
    // make non spec (ROB)
    input   wire logic                      commit0,
    input   wire logic                      commit1,
    // store conflict interface
    input   wire logic [PHYS-3:0]           conflict_address_i,
    input   wire logic [3:0]                conflict_bm_i,
    output  wire logic [31:0]               conflict_data_o,
    output  wire logic [3:0]                conflict_bm_o,
    output  wire logic                      conflict_resolvable_o,
    output  wire logic                      conflict_res_valid_o,
    input   wire logic                      cache_done,
    output       logic [PHYS-3:0]           store_address_o,
    output       logic [31:0]               store_data_o,
    output       logic [3:0]                store_bm_o,
    output       logic                      store_valid_o,
    output       logic                      no_nonspec
);
    reg [PHYS-3:0] physical_addresses [0:9];
    reg [31:0] data [0:9];
    reg [3:0] bitmask [0:9];
    reg [9:0] io ;
    reg [9:0] speculative ;
    reg [9:0] vld = 0;

    wire enqueue_full = &vld;
    wire logic [PHYS-3:0]           working_enqueue_address_i;
    wire logic [31:0]               working_enqueue_data_i;
    wire logic [3:0]                working_enqueue_bm_i;
    wire logic                      working_enqueue_io_i;
    wire logic [4:0]                working_enqueue_rob_i; wire working_valid;
    skdbf #(.DW(72)) stskdbf (cpu_clk_i, flush_i, enqueue_full, {working_enqueue_address_i, working_enqueue_data_i, working_enqueue_bm_i, working_enqueue_io_i,
    working_enqueue_rob_i}, working_valid, enqueue_full_o, {enqueue_address_i, enqueue_data_i, enqueue_bm_i, enqueue_io_i, enqueue_rob_i}, enqueue_en_i);
    // conflict resolver
    logic [31:0] conflict_dq_id;
    logic [9:0] conflicts;
    logic onehot0, onehot1;
    onehot6to1 onehot0inst (conflicts[5:0], onehot0);
    onehot6to1 onehot1inst ({2'b00, conflicts[9:6]}, onehot1);
    logic [3:0] conflict_bitmask;
    logic conflict_io;
    assign conflict_resolvable_o = (onehot0^onehot1)&!conflict_io; // either can be onehot but not both
    assign conflict_data_o = conflict_dq_id;
    assign conflict_bm_o = conflict_bitmask;
    assign conflict_res_valid_o = |conflicts;
    for (genvar i = 0; i < 10; i++) begin : _comparison
        assign conflicts[i] = (physical_addresses[i]==conflict_address_i)&&|(bitmask[i]&conflict_bm_i)&&vld[i];
    end
    
    always_comb begin
        casez (conflicts)
            10'bzzzzzzzzz1: begin
                conflict_dq_id = data[0];
                conflict_bitmask = bitmask[0];
                conflict_io = io[0];
            end
            10'bzzzzzzzz10: begin
                conflict_dq_id = data[1];
                conflict_bitmask = bitmask[1];
                conflict_io = io[1];
            end
            10'bzzzzzzz100: begin
                conflict_dq_id = data[2];            
                conflict_bitmask = bitmask[2];
                conflict_io = io[2];
            end
            10'bzzzzzz1000: begin
                conflict_dq_id = data[3];
                conflict_bitmask = bitmask[3];
                conflict_io = io[3];
            end
            10'bzzzzz10000: begin
                conflict_dq_id = data[4];
                conflict_bitmask = bitmask[4];
                conflict_io = io[4];
            end
            10'bzzzz100000: begin
                conflict_dq_id = data[5];
                conflict_bitmask = bitmask[5];
                conflict_io = io[5];
            end
            10'bzzz1000000: begin
                conflict_dq_id = data[6];
                conflict_bitmask = bitmask[6];
                conflict_io = io[6];
            end
            10'bzz10000000: begin
                conflict_dq_id = data[7];
                conflict_bitmask = bitmask[7];
                conflict_io = io[7];
            end
            10'bz100000000: begin
                conflict_dq_id = data[8];
                conflict_bitmask = bitmask[8];
                conflict_io = io[8];
            end
            10'b1000000000: begin
                conflict_dq_id = data[9];
                conflict_bitmask = bitmask[9];
                conflict_io = io[9];
            end
            default: begin
                conflict_dq_id = data[0];
                conflict_bitmask = bitmask[0];
                conflict_io = io[0];
            end
        endcase
    end
    wire [9:0] shift;
    wire [9:0] spec;
    assign shift[0] = !vld[0];
    assign shift[1] = !(vld[1] & vld[0]);
    assign shift[2] = !(vld[2] & vld[1] & vld[0]);
    assign shift[3] = !(vld[3] & vld[2] & vld[1] & vld[0]);
    assign shift[4] = !(vld[4] & vld[3] & vld[2] & vld[1] & vld[0]);
    assign shift[5] = !(vld[5] & vld[4] & vld[3] & vld[2] & vld[1] & vld[0]);
    assign shift[6] = !(vld[6] & vld[5] & vld[4] & vld[3] & vld[2] & vld[1] & vld[0]);
    assign shift[7] = !(vld[7] & vld[6] & vld[5] & vld[4] & vld[3] & vld[2] & vld[1] & vld[0]);
    assign shift[8] = !(vld[8] & vld[7] & vld[6] & vld[5] & vld[4] & vld[3] & vld[2] & vld[1] & vld[0]);
    assign shift[9] = !(vld[9] & vld[8] & vld[7] & vld[6] & vld[5] & vld[4] & vld[3] & vld[2] & vld[1] & vld[0]);
    logic [9:0] ddec;
    logic [9:0] vldl;
    always_comb begin
        casez (vld&speculative)
            10'bzzzzzzzzz1: ddec = 10'b0000000001;
            10'bzzzzzzzz10: ddec = 10'b0000000010;
            10'bzzzzzzz100: ddec = 10'b0000000100;
            10'bzzzzzz1000: ddec = 10'b0000001000;
            10'bzzzzz10000: ddec = 10'b0000010000;
            10'bzzzz100000: ddec = 10'b0000100000;
            10'bzzz1000000: ddec = 10'b0001000000;
            10'bzz10000000: ddec = 10'b0010000000;
            10'bz100000000: ddec = 10'b0100000000;
            10'b1000000000: ddec = 10'b1000000000;
            default: ddec = 10'h0;
        endcase
    end
    logic [9:0] ddec2;
    always_comb begin
        casez (vld&speculative&~ddec)
            10'bzzzzzzzzz1: ddec2 = 10'b0000000001;
            10'bzzzzzzzz10: ddec2 = 10'b0000000010;
            10'bzzzzzzz100: ddec2 = 10'b0000000100;
            10'bzzzzzz1000: ddec2 = 10'b0000001000;
            10'bzzzzz10000: ddec2 = 10'b0000010000;
            10'bzzzz100000: ddec2 = 10'b0000100000;
            10'bzzz1000000: ddec2 = 10'b0001000000;
            10'bzz10000000: ddec2 = 10'b0010000000;
            10'bz100000000: ddec2 = 10'b0100000000;
            10'b1000000000: ddec2 = 10'b1000000000;
            default: ddec2 = 10'h0;
        endcase
    end
    logic [9:0] cdec;
    logic [31:0] cache_dq;
    logic [PHYS-3:0] address;
    logic [3:0] bm;
    always_comb begin
        casez (vld&~speculative)
            10'bzzzzzzzzz1: begin
                cdec = 10'b0000000001;
                cache_dq = data[0];
                address = physical_addresses[0];
                bm = bitmask[0];
            end
            10'bzzzzzzzz10: begin
                cdec = 10'b0000000010;
                cache_dq = data[1];
                address = physical_addresses[1];
                bm = bitmask[1];
            end
            10'bzzzzzzz100: begin
                cdec = 10'b0000000100;
                cache_dq = data[2];
                address = physical_addresses[2];
                bm = bitmask[2];
            end
            10'bzzzzzz1000: begin
                cdec = 10'b0000001000;
                cache_dq = data[3];
                address = physical_addresses[3];
                bm = bitmask[3];
            end
            10'bzzzzz10000: begin
                cdec = 10'b0000010000;
                cache_dq = data[4];
                address = physical_addresses[4];
                bm = bitmask[4];
            end
            10'bzzzz100000: begin
                cdec = 10'b0000100000;
                cache_dq = data[5];
                address = physical_addresses[5];
                bm = bitmask[5];
            end
            10'bzzz1000000: begin
                cdec = 10'b0001000000;
                cache_dq = data[6];
                address = physical_addresses[6];
                bm = bitmask[6];
            end
            10'bzz10000000: begin
                cdec = 10'b0010000000;
                cache_dq = data[7];
                address = physical_addresses[7];
                bm = bitmask[7];
            end
            10'bz100000000: begin
                cdec = 10'b0100000000;
                cache_dq = data[8];
                address = physical_addresses[8];
                bm = bitmask[8];
            end
            10'b1000000000: begin
                cdec = 10'b1000000000;
                cache_dq = data[9];
                address = physical_addresses[9];
                bm = bitmask[9];
            end
            default: begin
                cdec = 10'h0;
                cache_dq = data[0];
                address = physical_addresses[0];
                bm = bitmask[0];
            end
        endcase
    end
    always_ff @(posedge cpu_clk_i) begin
        physical_addresses[9] <= shift[9] ? working_enqueue_address_i : physical_addresses[9];
        bitmask[9] <= shift[9] ? working_enqueue_bm_i : bitmask[9];
        data[9] <= shift[9] ? working_enqueue_data_i : data[9];
        io[9] <= shift[9] ? working_enqueue_io_i : io[9];
        vld[9] <= shift[9] ? !flush_i&working_valid : vldl[9]; 
        speculative[9] <= shift[9] ? 1'b1 : spec[9];
    end

    for (genvar i = 0; i < 10; i++) begin : _spec
        assign spec[i] = speculative[i]&!(ddec[i]&(commit0|commit1))&!(ddec2[i]&(commit0&commit1));
    end
    for (genvar i = 0; i < 10; i++) begin : _valid
        assign vldl[i] = vld[i]&(spec[i] ? !flush_i : !(cdec[i]&cache_done));
    end
    for (genvar i = 9; i > 0; i--) begin : _shift
        always_ff @(posedge cpu_clk_i) begin
            physical_addresses[i-1] <= shift[i-1] ? physical_addresses[i] : physical_addresses[i-1];
            bitmask[i-1] <= shift[i-1] ? bitmask[i] : bitmask[i-1];
            data[i-1] <= shift[i-1] ? data[i] : data[i-1];
            io[i-1] <= shift[i-1] ? io[i] : io[i-1];
            speculative[i-1] <= shift[i-1] ? spec[i] : spec[i-1];
            vld[i-1] <= shift[i-1] ? vldl[i] : vldl[i-1];
        end
    end
    
    always_ff @(posedge cpu_clk_i) begin
        if ((|cdec)&!store_valid_o) begin
            store_address_o <= address;
            store_bm_o <= bm;
            store_data_o <= cache_dq;
            store_valid_o <= 1;
        end
        else if (cache_done) begin
            store_valid_o <= 1'b0;
        end
    end
    assign no_nonspec = !(|((~speculative)&vld));// inner expression 1 when there are valid instructions that are not speculative, since the other modules use
    // store buffer empty, store buffer empty is high when inner expression is 0
    assign complete_vld = working_valid&!enqueue_full; assign complete = working_enqueue_rob_i;
endmodule
