module EX00 (
    input   wire logic                              cpu_clock_i,
    input   wire logic                              flush_i,

    input   wire logic [17:0]                       data_i,
    input   wire logic                              valid_i,

    output  wire logic [5:0]                        rs1_o,
    output  wire logic [5:0]                        rs2_o,
    input   wire logic [31:0]                       rs1_data_i,
    input   wire logic [31:0]                       rs2_data_i,

    output  wire logic [4:0]                        rob_o,
    // instruction ram
    input   wire logic [6:0]                        opcode_i,
    input   wire logic [5:0]                        ins_type, // 0 = ALU, 1 = JAL, 2 = JALR, 3 = LUI, 4 - AUIPC
    input   wire logic                              imm_i,
    input   wire logic [31:0]                       immediate_i,
    input   wire logic [5:0]                        dest_i,
    input   wire logic [29:0]                       pc_i,
    // Branch info
    input   wire logic  [1:0]                       bm_pred_i,
    input   wire logic  [1:0]                       btype_i,
    input   wire logic                              btb_vld_i,
    input   wire logic  [29:0]                      btb_target_i,
    input   wire logic                              btb_way_i,
    input   wire logic                              btb_idx_i,

    output       logic [31:0]                       bnch_operand_1,
    output       logic [31:0]                       bnch_operand_2,
    output       logic [31:0]                       bnch_offset,
    output       logic [29:0]                       bnch_pc,
    output       logic                              bnch_auipc,
    output       logic                              bnch_lui,
    output       logic                              bnch_jal,
    output       logic                              bnch_jalr,
    output       logic [2:0]                        bnch_bnch_cond,
    output       logic [5:0]                        bnch_rob_id_o,
    output       logic [5:0]                        bnch_dest_o, 
    output       logic  [1:0]                       bnch_bm_pred_o,
    output       logic  [1:0]                       bnch_btype_o,
    output       logic                              bnch_btb_vld_o,
    output       logic  [29:0]                      bnch_btb_target_o,
    output       logic                              bnch_btb_way_o,
    output       logic                              bnch_valid_o,

    output       logic [31:0]                       alu_a,
    output       logic [31:0]                       alu_b,
    output       logic [6:0]                        alu_opc,
    output       logic [4:0]                        alu_rob_id,
    output       logic [5:0]                        alu_dest,
    output       logic                              alu_valid,

    output       logic [31:0]                       valu_a,
    output       logic [31:0]                       valu_b,
    output       logic [6:0]                        valu_opc,
    output       logic [4:0]                        valu_rob_id,
    output       logic [5:0]                        valu_dest,
    output       logic                              valu_valid,

    output       logic [5:0]                        wakeup_dest,
    output       logic                              wakeup_valid
);
    assign rob_o = data_i[4:0];
    assign rs1_o = data_i[11:6];
    assign rs2_o = data_i[17:12];
    initial wakeup_valid = 0; initial alu_valid = 0;
    always_ff @(posedge cpu_clock_i) begin
        if (valid_i&!flush_i) begin
            alu_a <= rs1_data_i;
            alu_b <= imm_i ? immediate_i :  rs2_data_i;
            alu_opc <= opcode_i;
            alu_rob_id <= data_i[4:0];
            alu_dest <= dest_i;
            alu_valid <= ins_type[0];
            valu_a <= rs1_data_i;
            valu_b <= rs2_data_i;
            valu_opc <= opcode_i;
            valu_rob_id <= data_i[4:0];
            valu_dest <= dest_i;
            valu_valid <= ins_type[5];
            bnch_operand_1 <= rs1_data_i; bnch_operand_2 <= rs2_data_i;
            bnch_offset <= immediate_i; 
            bnch_pc <= {pc_i[29:1], pc_i[0] ? 1'b1 : data_i[0]};
            bnch_auipc <= ins_type[4]; bnch_lui <= ins_type[3]; bnch_jal <= ins_type[1]; bnch_jalr <= ins_type[2];
            bnch_bnch_cond <= opcode_i[2:0]; bnch_rob_id_o <= data_i[5:0]; bnch_dest_o <= dest_i; bnch_bm_pred_o <= bm_pred_i;
            bnch_btype_o <= btype_i;
            bnch_btb_vld_o <= btb_vld_i&(btb_idx_i==(pc_i[0] ? 1'b1 : data_i[0]));
            bnch_btb_target_o <= btb_target_i;
            bnch_btb_way_o <= btb_way_i; // mask off appropriately
            wakeup_dest <= dest_i;
            bnch_valid_o <= ((|ins_type[4:1])||(!ins_type[0]&!ins_type[5]));
            wakeup_valid <= (|ins_type);
        end else begin
            alu_valid <= 0; bnch_valid_o <= 0; valu_valid <= 0;
        end
    end

endmodule
