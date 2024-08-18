module irf
(    
    input       wire logic           clk_i,
    input       wire logic              p0_we_i,
    input       wire logic [31:0]       p0_we_data,
    input       wire logic [5:0]        p0_we_dest,

    input       wire logic              p1_we_i,
    input       wire logic [31:0]       p1_we_data,
    input       wire logic [5:0]        p1_we_dest,

    input       wire logic              p2_we_i,
    input       wire logic [31:0]       p2_we_data,
    input       wire logic [5:0]        p2_we_dest,

    input       wire logic [5:0]        p0_rd_src,
    output      logic [31:0]            p0_rd_datas,

    input       wire logic [5:0]        p1_rd_src,
    output      logic [31:0]            p1_rd_datas,

    input       wire logic [5:0]        p2_rd_src,
    output      logic [31:0]            p2_rd_datas,

    input       wire logic [5:0]        p3_rd_src,
    output      logic [31:0]            p3_rd_datas,

    input       wire logic [5:0]        p4_rd_src,
    output      logic [31:0]            p4_rd_datas,

    input       wire logic [5:0]        p5_rd_src,
    output      logic [31:0]            p5_rd_datas
);

    reg [31:0] file00 [0:63]; 
    reg [31:0] file01 [0:63]; 
    reg [31:0] file10 [0:63]; 
    // forwarding network over ALUs
    assign p0_rd_datas = (p0_we_dest==p0_rd_src)&&(p0_we_i) ? p0_we_data :  (p1_we_dest==p0_rd_src)&&(p1_we_i) ? p1_we_data :
    file00[p0_rd_src] ^ file01[p0_rd_src] ^ file10[p0_rd_src];
    assign p1_rd_datas = (p0_we_dest==p1_rd_src)&&(p0_we_i) ? p0_we_data :  (p1_we_dest==p1_rd_src)&&(p1_we_i) ? p1_we_data :
    file00[p1_rd_src] ^ file01[p1_rd_src] ^ file10[p1_rd_src];
    assign p2_rd_datas = (p0_we_dest==p2_rd_src)&&(p0_we_i) ? p0_we_data :  (p1_we_dest==p2_rd_src)&&(p1_we_i) ? p1_we_data :
    file00[p2_rd_src] ^ file01[p2_rd_src] ^ file10[p2_rd_src];
    assign p3_rd_datas = (p0_we_dest==p3_rd_src)&&(p0_we_i) ? p0_we_data :  (p1_we_dest==p3_rd_src)&&(p1_we_i) ? p1_we_data :
    file00[p3_rd_src] ^ file01[p3_rd_src] ^ file10[p3_rd_src];
    assign p4_rd_datas = (p0_we_dest==p4_rd_src)&&(p0_we_i) ? p0_we_data :  (p1_we_dest==p4_rd_src)&&(p1_we_i) ? p1_we_data :
    file00[p4_rd_src] ^ file01[p4_rd_src] ^ file10[p4_rd_src];
    assign p5_rd_datas = (p0_we_dest==p5_rd_src)&&(p0_we_i) ? p0_we_data :  (p1_we_dest==p5_rd_src)&&(p1_we_i) ? p1_we_data :
    file00[p5_rd_src] ^ file01[p5_rd_src] ^ file10[p5_rd_src];

    always_ff @(posedge clk_i) begin
        if (p0_we_i) begin
            file00[p0_we_dest] <= p0_we_data ^ file01[p0_we_dest] ^ file10[p0_we_dest];
        end
        if (p1_we_i) begin
            file01[p1_we_dest] <= p1_we_data ^ file00[p1_we_dest] ^ file10[p1_we_dest];
        end
        if (p2_we_i) begin
            file10[p2_we_dest] <= p2_we_data ^ file00[p2_we_dest] ^ file01[p2_we_dest];
        end
    end
endmodule
