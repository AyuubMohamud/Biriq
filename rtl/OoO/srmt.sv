module srmt (
    input   wire logic          cpu_clk_i,
    input   wire logic          flush_i,
    // Inst0
    input   wire logic [4:0]    p0_logical_reg_i,
    output  wire logic [5:0]    p0_phys_reg_o,
    input   wire logic [4:0]    p1_logical_reg_i,
    output  wire logic [5:0]    p1_phys_reg_o,
    // Inst1
    input   wire logic [4:0]    p2_logical_reg_i,
    output  wire logic [5:0]    p2_phys_reg_o,
    input   wire logic [4:0]    p3_logical_reg_i,
    output  wire logic [5:0]    p3_phys_reg_o,
    input   wire logic [4:0]    arch_reg0,
    input   wire logic [5:0]    phys_reg0,
    input   wire logic [4:0]    arch_reg1,
    input   wire logic [5:0]    phys_reg1,
    input   wire logic [4:0]    p4_logical_reg_i,
    output  wire logic [5:0]    p4_phys_reg_o,
    input   wire logic [4:0]    p5_logical_reg_i,
    output  wire logic [5:0]    p5_phys_reg_o,
    input   wire logic [4:0]    w0_logical_reg_i,
    input   wire logic [5:0]    w0_phys_reg_i,
    input   wire logic          w0_we_i,
    input   wire logic [4:0]    w1_logical_reg_i,
    input   wire logic [5:0]    w1_phys_reg_i,
    input   wire logic          w1_we_i
);
    reg [5:0] RAMA [0:31];
    initial RAMA[0] = 6'b000000;
    initial RAMA[1] = 6'b000001;
    initial RAMA[2] = 6'b000010;
    initial RAMA[3] = 6'b000011;
    initial RAMA[4] = 6'b000100;
    initial RAMA[5] = 6'b000101;
    initial RAMA[6] = 6'b000110;
    initial RAMA[7] = 6'b000111;
    initial RAMA[8] = 6'b001000;
    initial RAMA[9] = 6'b001001;
    initial RAMA[10] = 6'b001010;
    initial RAMA[11] = 6'b001011;
    initial RAMA[12] = 6'b001100;
    initial RAMA[13] = 6'b001101;
    initial RAMA[14] = 6'b001110;
    initial RAMA[15] = 6'b001111;
    initial RAMA[16] = 6'b010000;
    initial RAMA[17] = 6'b010001;
    initial RAMA[18] = 6'b010010;
    initial RAMA[19] = 6'b010011;
    initial RAMA[20] = 6'b010100;
    initial RAMA[21] = 6'b010101;
    initial RAMA[22] = 6'b010110;
    initial RAMA[23] = 6'b010111;
    initial RAMA[24] = 6'b011000;
    initial RAMA[25] = 6'b011001;
    initial RAMA[26] = 6'b011010;
    initial RAMA[27] = 6'b011011;
    initial RAMA[28] = 6'b011100;
    initial RAMA[29] = 6'b011101;
    initial RAMA[30] = 6'b011110;
    initial RAMA[31] = 6'b011111;

    reg [5:0] RAMB [0:31];
    for (genvar i = 0; i < 32; i++) begin : _0
        initial RAMB[i] = 6'h00;
    end
    wire dnw0 = w1_we_i&(w0_logical_reg_i==w1_logical_reg_i)&w0_we_i;
    always @(posedge cpu_clk_i) begin
        if (flush_i) begin
            RAMA[arch_reg0] <= phys_reg0 ^ RAMB[arch_reg0];
        end
        else if (w0_we_i&!dnw0) begin
            RAMA[w0_logical_reg_i] <= w0_phys_reg_i ^ RAMB[w0_logical_reg_i];
        end
        if (flush_i) begin
            RAMB[arch_reg1] <= phys_reg1 ^ RAMA[arch_reg1];
        end
        else if (w1_we_i) begin
            RAMB[w1_logical_reg_i] <= w1_phys_reg_i ^ RAMA[w1_logical_reg_i];
        end
    end
    assign p0_phys_reg_o = RAMB[p0_logical_reg_i] ^ RAMA[p0_logical_reg_i];
    assign p1_phys_reg_o = RAMB[p1_logical_reg_i] ^ RAMA[p1_logical_reg_i];
    assign p2_phys_reg_o = w0_we_i&&(p2_logical_reg_i==w0_logical_reg_i) ? w0_phys_reg_i : RAMB[p2_logical_reg_i] ^ RAMA[p2_logical_reg_i];
    assign p3_phys_reg_o = w0_we_i&&(p3_logical_reg_i==w0_logical_reg_i) ? w0_phys_reg_i : RAMB[p3_logical_reg_i] ^ RAMA[p3_logical_reg_i];
    assign p4_phys_reg_o = RAMB[p4_logical_reg_i] ^ RAMA[p4_logical_reg_i];
    assign p5_phys_reg_o = RAMB[p5_logical_reg_i] ^ RAMA[p5_logical_reg_i];
endmodule
