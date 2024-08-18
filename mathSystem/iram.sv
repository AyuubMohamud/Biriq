module iram (
    input   wire logic                      cpu_clk_i,
    
    input   wire logic [6:0]                ins0_opcode_i,
    input   wire logic [4:0]                ins0_ins_type, // 0 = ALU, 1 = JAL, 2 = JALR, 3 = LUI, 4 - AUIPC, 5 - Branch
    input   wire logic                      ins0_imm_i,
    input   wire logic [31:0]               ins0_immediate_i,
    input   wire logic [5:0]                ins0_dest_i,
    input   wire logic                      ins0_valid,
    input   wire logic [6:0]                ins1_opcode_i,
    input   wire logic [4:0]                ins1_ins_type, // 0 = ALU, 1 = JAL, 2 = JALR, 3 = LUI, 4 - AUIPC, 5 - Branch
    input   wire logic                      ins1_imm_i,
    input   wire logic [31:0]               ins1_immediate_i,
    input   wire logic [5:0]                ins1_dest_i,
    input   wire logic                      ins1_valid,
    input   wire logic [3:0]                pack_id,

    output  wire logic [6:0]                alu0_opcode_o,
    output  wire logic [4:0]                alu0_ins_type,
    output  wire logic                      alu0_imm_o,
    output  wire logic [31:0]               alu0_immediate_o,
    output  wire logic [5:0]                alu0_dest_o,
    input   wire logic [4:0]                alu0_rob_i,
    output  wire logic [6:0]                alu1_opcode_o,
    output  wire logic [4:0]                alu1_ins_type, 
    output  wire logic                      alu1_imm_o,
    output  wire logic [31:0]               alu1_immediate_o,
    output  wire logic [5:0]                alu1_dest_o,
    input   wire logic [4:0]                alu1_rob_i
);
    // 2x2 ram
    reg [50:0] iram0 [0:15];
    reg [50:0] iram1 [0:15];
    
    always_ff @(posedge cpu_clk_i) begin
        if (ins0_valid) begin
            iram0[pack_id] <= {ins0_opcode_i, ins0_ins_type, ins0_imm_i, ins0_immediate_i, ins0_dest_i};
        end
        if (ins1_valid) begin
            iram1[pack_id] <= {ins1_opcode_i, ins1_ins_type, ins1_imm_i, ins1_immediate_i, ins1_dest_i};
        end
    end
    assign {alu0_opcode_o,
    alu0_ins_type,
    alu0_imm_o,
    alu0_immediate_o,
    alu0_dest_o} = 
    alu0_rob_i[0] ? iram1[alu0_rob_i[4:1]] : iram0[alu0_rob_i[4:1]];
    assign {alu1_opcode_o,
    alu1_ins_type, 
    alu1_imm_o,
    alu1_immediate_o,
    alu1_dest_o} = alu1_rob_i[0] ? iram1[alu1_rob_i[4:1]] : iram0[alu1_rob_i[4:1]];
endmodule
