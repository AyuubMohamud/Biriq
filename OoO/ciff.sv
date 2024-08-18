module ciff (
    input   wire logic                  cpu_clk_i,
    input   wire logic                  flush_i,

    input   wire logic [4:0]            alu0_rob_slot_i,
    input   wire logic                  alu0_rob_complete_i,

    input   wire logic [4:0]            alu1_rob_slot_i,
    input   wire logic                  alu1_rob_complete_i,

    input   wire logic [4:0]            agu0_rob_slot_i,
    input   wire logic                  agu0_rob_complete_i,

    input   wire logic [4:0]            ldq_rob_slot_i,
    input   wire logic                  ldq_rob_complete_i,

    input   wire logic [4:0]            rob0_status,
    input   wire logic                  commit0,
    output  wire logic                  rob0_status_o,

    input   wire logic [4:0]            rob1_status,
    input   wire logic                  commit1,
    output  wire logic                  rob1_status_o
);
    reg [31:0] rob_status_bits = 0;

    for (genvar i = 0; i < 32; i = i + 2) begin : rob0_x
        always_ff @(posedge cpu_clk_i) begin
            rob_status_bits[i] <= flush_i ? 1'b0 : (rob0_status==i)&&commit0  ? 1'b0 : (alu0_rob_slot_i==i)&&alu0_rob_complete_i ? 1'b1 : 
            (alu1_rob_slot_i==i)&&alu1_rob_complete_i ? 1'b1 : (agu0_rob_slot_i==i)&&agu0_rob_complete_i ? 1'b1 : (ldq_rob_slot_i==i)&&ldq_rob_complete_i ? 1'b1 : rob_status_bits[i];
        end
    end
    for (genvar i = 1; i < 32; i = i + 2) begin : rob0_y
        always_ff @(posedge cpu_clk_i) begin
            rob_status_bits[i] <= flush_i ? 1'b0 : (rob1_status==i)&&commit1  ? 1'b0 : (alu0_rob_slot_i==i)&&alu0_rob_complete_i ? 1'b1 : 
            (alu1_rob_slot_i==i)&&alu1_rob_complete_i ? 1'b1 : (agu0_rob_slot_i==i)&&agu0_rob_complete_i ? 1'b1 : (ldq_rob_slot_i==i)&&ldq_rob_complete_i ? 1'b1 : rob_status_bits[i];
        end
    end
    assign rob0_status_o = rob_status_bits[rob0_status];
    assign rob1_status_o = rob_status_bits[rob1_status];
endmodule
