module rst (
    input   wire logic          clk_i,

    input   wire logic [5:0]    p0_vec_indx_i,
    input   wire logic          p0_busy_vld_i,
    input   wire logic [5:0]    p1_vec_indx_i,
    input   wire logic          p1_free_vld_i,
    input   wire logic          p1_busy_vld_i,

    input   wire logic [5:0]    p2_vec_indx_i,
    input   wire logic          p2_free_vld_i,
    input   wire logic [5:0]    p3_vec_indx_i,
    input   wire logic          p3_free_vld_i,
    input   wire logic [5:0]    p4_vec_indx_i,
    input   wire logic          p4_free_vld_i,
    
    input   wire logic [5:0]    r0_vec_indx_i,
    output  logic               r0_o,
    input   wire logic [5:0]    r1_vec_indx_i,
    output  logic               r1_o,
    input   wire logic [5:0]    r2_vec_indx_i,
    output  logic               r2_o,
    input   wire logic [5:0]    r3_vec_indx_i,
    output  logic               r3_o,
    input   wire logic [5:0]    r4_vec_indx_i,
    output  logic               r4_o,
    input   wire logic [5:0]    r5_vec_indx_i,
    output  logic               r5_o
);

    reg ffa [0:63]; // Busy port

    reg ffb [0:63]; // Busy port
    reg ffc [0:63]; // Free port
    reg ffd [0:63]; // Free port
    reg ffe [0:63]; // Free port
    initial begin
        for (integer i = 0; i < 64; i++) begin
            ffa[i] = 1'b1;
            ffb[i] = 1'b0;
            ffc[i] = 1'b0;
            ffd[i] = 1'b0;
            ffe[i] = 1'b0;
        end
    end
    always_ff @(posedge clk_i) begin
        if (p0_busy_vld_i) begin
            ffa[p0_vec_indx_i] <= (1'b0 ^ ffb[p0_vec_indx_i] ^ ffc[p0_vec_indx_i] ^ ffd[p0_vec_indx_i] ^ ffe[p0_vec_indx_i]);
        end
        if (p1_busy_vld_i|p1_free_vld_i) begin
            ffb[p1_vec_indx_i] <= (p1_free_vld_i ^ ffa[p1_vec_indx_i] ^ ffc[p1_vec_indx_i] ^ ffd[p1_vec_indx_i] ^ ffe[p1_vec_indx_i]);
        end
        if (p2_free_vld_i) begin
            ffc[p2_vec_indx_i] <= (1'b1 ^ ffb[p2_vec_indx_i] ^ ffa[p2_vec_indx_i] ^ ffd[p2_vec_indx_i] ^ ffe[p2_vec_indx_i]);
        end
        if (p3_free_vld_i) begin
            ffd[p3_vec_indx_i] <= (1'b1 ^ ffb[p3_vec_indx_i] ^ ffc[p3_vec_indx_i] ^ ffa[p3_vec_indx_i] ^ ffe[p3_vec_indx_i]);
        end
        if (p4_free_vld_i) begin
            ffe[p4_vec_indx_i] <= (ffa[p4_vec_indx_i] ^ ffb[p4_vec_indx_i] ^ ffc[p4_vec_indx_i] ^ ffd[p4_vec_indx_i]  ^ 1'b1);
        end
    end
    // remove unneccsary comparisons for combinatinal driving.
    assign r0_o = (ffa[r0_vec_indx_i] ^ ffb[r0_vec_indx_i] ^ ffc[r0_vec_indx_i] ^ ffd[r0_vec_indx_i] ^ ffe[r0_vec_indx_i]);
    assign r1_o = (ffa[r1_vec_indx_i] ^ ffb[r1_vec_indx_i] ^ ffc[r1_vec_indx_i] ^ ffd[r1_vec_indx_i] ^ ffe[r1_vec_indx_i]);
    assign r2_o = (ffa[r2_vec_indx_i] ^ ffb[r2_vec_indx_i] ^ ffc[r2_vec_indx_i] ^ ffd[r2_vec_indx_i] ^ ffe[r2_vec_indx_i])&(!((p0_vec_indx_i == r2_vec_indx_i)&&p0_busy_vld_i)||(p0_vec_indx_i==0));
    assign r3_o = (ffa[r3_vec_indx_i] ^ ffb[r3_vec_indx_i] ^ ffc[r3_vec_indx_i] ^ ffd[r3_vec_indx_i] ^ ffe[r3_vec_indx_i]) && (!((p0_vec_indx_i == r3_vec_indx_i)&&p0_busy_vld_i)||(p0_vec_indx_i==0));
    assign r4_o = (ffa[r4_vec_indx_i] ^ ffb[r4_vec_indx_i] ^ ffc[r4_vec_indx_i] ^ ffd[r4_vec_indx_i] ^ ffe[r4_vec_indx_i]);
    assign r5_o = (ffa[r5_vec_indx_i] ^ ffb[r5_vec_indx_i] ^ ffc[r5_vec_indx_i] ^ ffd[r5_vec_indx_i] ^ ffe[r5_vec_indx_i]);
endmodule
