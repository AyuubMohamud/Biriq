module newStoreBuffer #(parameter PHYS = 32, parameter ENTRIES = 10) (
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
    reg [PHYS-3:0] physical_addresses [0:ENTRIES-1];
    reg [31:0] data [0:ENTRIES-1];
    reg [3:0] bitmask [0:ENTRIES-1];
    reg [ENTRIES-1:0] io ;
    reg [ENTRIES-1:0] speculative ;
    reg [ENTRIES-1:0] vld = 0;

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
    logic [ENTRIES-1:0] conflicts;
    wire onehot;
    genOneHot #(ENTRIES) onehotgen (conflicts, onehot);
    logic [3:0] conflict_bitmask;
    logic conflict_io;
    assign conflict_resolvable_o = onehot&!conflict_io;
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
            if (conflicts[i]&!FINISHSEL) begin
                conflict_dq_id = data[i];
                conflict_bitmask = bitmask[i];
                conflict_io = io[i];
            end
        end
    end
    //always_comb begin
    //    casez (conflicts)
    //        10'bzzzzzzzzz1: begin
    //            conflict_dq_id = data[0];
    //            conflict_bitmask = bitmask[0];
    //            conflict_io = io[0];
    //        end
    //        10'bzzzzzzzz10: begin
    //            conflict_dq_id = data[1];
    //            conflict_bitmask = bitmask[1];
    //            conflict_io = io[1];
    //        end
    //        10'bzzzzzzz100: begin
    //            conflict_dq_id = data[2];            
    //            conflict_bitmask = bitmask[2];
    //            conflict_io = io[2];
    //        end
    //        10'bzzzzzz1000: begin
    //            conflict_dq_id = data[3];
    //            conflict_bitmask = bitmask[3];
    //            conflict_io = io[3];
    //        end
    //        10'bzzzzz10000: begin
    //            conflict_dq_id = data[4];
    //            conflict_bitmask = bitmask[4];
    //            conflict_io = io[4];
    //        end
    //        10'bzzzz100000: begin
    //            conflict_dq_id = data[5];
    //            conflict_bitmask = bitmask[5];
    //            conflict_io = io[5];
    //        end
    //        10'bzzz1000000: begin
    //            conflict_dq_id = data[6];
    //            conflict_bitmask = bitmask[6];
    //            conflict_io = io[6];
    //        end
    //        10'bzz10000000: begin
    //            conflict_dq_id = data[7];
    //            conflict_bitmask = bitmask[7];
    //            conflict_io = io[7];
    //        end
    //        10'bz100000000: begin
    //            conflict_dq_id = data[8];
    //            conflict_bitmask = bitmask[8];
    //            conflict_io = io[8];
    //        end
    //        10'b1000000000: begin
    //            conflict_dq_id = data[9];
    //            conflict_bitmask = bitmask[9];
    //            conflict_io = io[9];
    //        end
    //        default: begin
    //            conflict_dq_id = data[0];
    //            conflict_bitmask = bitmask[0];
    //            conflict_io = io[0];
    //        end
    //    endcase
    //end
    wire [ENTRIES-1:0] shift;
    wire [ENTRIES-1:0] spec;
    for (genvar i = 0; i < ENTRIES; i++) begin : shift_logic
        assign shift[i] = !(&vld[i:0]);
    end
    //assign shift[0] = !vld[0];
    //assign shift[1] = !(vld[1] & vld[0]);
    //assign shift[2] = !(vld[2] & vld[1] & vld[0]);
    //assign shift[3] = !(vld[3] & vld[2] & vld[1] & vld[0]);
    //assign shift[4] = !(vld[4] & vld[3] & vld[2] & vld[1] & vld[0]);
    //assign shift[5] = !(vld[5] & vld[4] & vld[3] & vld[2] & vld[1] & vld[0]);
    //assign shift[6] = !(vld[6] & vld[5] & vld[4] & vld[3] & vld[2] & vld[1] & vld[0]);
    //assign shift[7] = !(vld[7] & vld[6] & vld[5] & vld[4] & vld[3] & vld[2] & vld[1] & vld[0]);
    //assign shift[8] = !(vld[8] & vld[7] & vld[6] & vld[5] & vld[4] & vld[3] & vld[2] & vld[1] & vld[0]);
    //assign shift[9] = !(vld[9] & vld[8] & vld[7] & vld[6] & vld[5] & vld[4] & vld[3] & vld[2] & vld[1] & vld[0]);
    logic [ENTRIES-1:0] ddec;
    logic [ENTRIES-1:0] vldl;
    logic FINISHSEL2;
    always_comb begin
        FINISHSEL2 = '0;
        ddec = '0;
        for (integer i = 0; i < ENTRIES; i++) begin
            if (vld[i]&speculative[i]&!FINISHSEL2) begin
                FINISHSEL2 = 1;
                ddec[i] = 1;
            end
        end
    end
    //always_comb begin
    //    casez (vld&speculative)
    //        10'bzzzzzzzzz1: ddec = 10'b0000000001;
    //        10'bzzzzzzzz10: ddec = 10'b0000000010;
    //        10'bzzzzzzz100: ddec = 10'b0000000100;
    //        10'bzzzzzz1000: ddec = 10'b0000001000;
    //        10'bzzzzz10000: ddec = 10'b0000010000;
    //        10'bzzzz100000: ddec = 10'b0000100000;
    //        10'bzzz1000000: ddec = 10'b0001000000;
    //        10'bzz10000000: ddec = 10'b0010000000;
    //        10'bz100000000: ddec = 10'b0100000000;
    //        10'b1000000000: ddec = 10'b1000000000;
    //        default: ddec = 10'h0;
    //    endcase
    //end
    logic [ENTRIES-1:0] ddec2;
    logic FINISHSEL3;
    always_comb begin
        FINISHSEL3 = '0;
        ddec2 = '0;
        for (integer i = 0; i < ENTRIES; i++) begin
            if (vld[i]&speculative[i]&!ddec[i]&!FINISHSEL3) begin
                FINISHSEL3 = 1;
                ddec2[i] = 1;
            end
        end
    end
    logic [ENTRIES-1:0] cdec;
    logic [31:0] cache_dq;
    logic [PHYS-3:0] address;
    logic [3:0] bm;
    logic FINISHSEL4;
    always_comb begin
        FINISHSEL4 = '0;
        cdec = '0;
        cache_dq = 'x;
        address = 'x;
        bm = 'x;
        for (integer i = 0; i < ENTRIES; i++) begin
            if (vld[i]&~speculative[i]&!FINISHSEL4) begin
                FINISHSEL4 = 1;
                cdec[i] = 1;
                cache_dq = data[i];
                address = physical_addresses[i];
                bm = bitmask[i];
            end
        end
    end
    always_ff @(posedge cpu_clk_i) begin
        physical_addresses[ENTRIES-1] <= shift[ENTRIES-1] ? working_enqueue_address_i : physical_addresses[ENTRIES-1];
        bitmask[ENTRIES-1] <= shift[ENTRIES-1] ? working_enqueue_bm_i : bitmask[ENTRIES-1];
        data[ENTRIES-1] <= shift[ENTRIES-1] ? working_enqueue_data_i : data[ENTRIES-1];
        io[ENTRIES-1] <= shift[ENTRIES-1] ? working_enqueue_io_i : io[ENTRIES-1];
        vld[ENTRIES-1] <= shift[ENTRIES-1] ? !flush_i&working_valid : vldl[ENTRIES-1]; 
        speculative[ENTRIES-1] <= shift[ENTRIES-1] ? 1'b1 : spec[ENTRIES-1];
    end

    for (genvar i = 0; i < ENTRIES; i++) begin : _spec
        assign spec[i] = speculative[i]&!(ddec[i]&(commit0|commit1))&!(ddec2[i]&(commit0&commit1));
    end
    for (genvar i = 0; i < ENTRIES; i++) begin : _valid
        assign vldl[i] = vld[i]&(spec[i] ? !flush_i : !(cdec[i]&cache_done));
    end
    for (genvar i = ENTRIES-1; i > 0; i--) begin : _shift
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
