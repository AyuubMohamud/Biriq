module mathSystem (
    input   wire logic                  cpu_clock_i,
    input   wire logic                  flush_i,

    input   wire logic [6:0]            ins0_opcode_i,
    input   wire logic [5:0]            ins0_ins_type,
    input   wire logic                  ins0_imm_i,
    input   wire logic [31:0]           ins0_immediate_i,
    input   wire logic [1:0]            ins0_hint_i,
    input   wire logic [5:0]            ins0_dest_i,
    input   wire logic                  ins0_valid,
    input   wire logic [6:0]            ins1_opcode_i,
    input   wire logic [5:0]            ins1_ins_type,
    input   wire logic                  ins1_imm_i,
    input   wire logic [31:0]           ins1_immediate_i,
    input   wire logic [5:0]            ins1_dest_i,
    input   wire logic [1:0]            ins1_hint_i,
    input   wire logic                  ins1_valid,
    input   wire logic [3:0]            pack_id,

    input   wire logic [29:0]           rn_pc_i,
    input   wire logic  [1:0]           rn_bm_pred_i,
    input   wire logic  [1:0]           rn_btype_i,
    input   wire logic                  rn_btb_vld_i,
    input   wire logic  [29:0]          rn_btb_target_i,
    input   wire logic                  rn_btb_way_i,
    input   wire logic                  rn_btb_idx_i,
    input   wire logic [3:0]            rn_btb_pack,
    input   wire logic                  rn_btb_wen,

    input   wire logic [18:0]   p0_data_i,
    input   wire logic          p0_vld_i,
    input   wire logic          p0_rs1_vld_i,
    input   wire logic          p0_rs2_vld_i,
    input   wire logic          p0_rs1_rdy,
    input   wire logic          p0_rs2_rdy,
    
    input   wire logic [18:0]   p1_data_i,
    input   wire logic          p1_vld_i,
    input   wire logic          p1_rs1_vld_i,
    input   wire logic          p1_rs2_vld_i,
    input   wire logic          p1_rs1_rdy,
    input   wire logic          p1_rs2_rdy,

    output  wire logic          p0_busy_o,
    output  wire logic          p1_busy_o,
    // MemorySystem
    input   wire logic          eu2_v,
    input   wire logic [5:0]    eu2_dest,
    // CIFF bitvector
    output  wire logic                  alu0_complete,
    output  wire logic [4:0]            alu0_rob_id,
    output  wire logic                  alu1_complete,
    output  wire logic [4:0]            alu1_rob_id,
    // RST bitvector
    output  wire logic                  alu0_reg_ready,
    output  wire logic [5:0]            alu0_reg_dest,
    output  wire logic                  alu1_reg_ready,
    output  wire logic [5:0]            alu1_reg_dest,
    // Register file
    output  wire logic [31:0]           p0_we_data,
    output  wire logic [5:0]            p0_we_dest,
    output  wire logic                  p0_wen,
    output  wire logic [31:0]           p1_we_data,
    output  wire logic [5:0]            p1_we_dest,
    output  wire logic                  p1_wen,
    output  wire logic [5:0]            ex00_rs1_o,
    output  wire logic [5:0]            ex00_rs2_o,
    input   wire logic [31:0]           ex00_rs1_data_i,
    input   wire logic [31:0]           ex00_rs2_data_i,
    output  wire logic [5:0]            ex10_rs1_o,
    output  wire logic [5:0]            ex10_rs2_o,
    input   wire logic [31:0]           ex10_rs1_data_i,
    input   wire logic [31:0]           ex10_rs2_data_i,
    // Control Unit
    output  wire logic [5:0]            excp_rob,
    output  wire logic [4:0]            excp_code,
    output  wire logic                  excp_valid,
    output  wire logic  [29:0]          c1_btb_vpc_o,
    output  wire logic  [29:0]          c1_btb_target_o,
    output  wire logic  [1:0]           c1_cntr_pred_o,
    output  wire logic                  c1_bnch_tkn_o,
    output  wire logic  [1:0]           c1_bnch_type_o,
    output  wire logic                  c1_bnch_present_o,
    output  wire logic                  c1_call_affirm_o,
    output  wire logic                  c1_ret_affirm_o,
    // BTB
    output  wire logic                  wb_btb_way_o,
    output  wire logic                  wb_btb_bm_mod_o
);
    wire logic [6:0]                alu0_opcode_o;
    wire logic [5:0]                alu0_ins_type;
    wire logic                      alu0_imm_o;
    wire logic [31:0]               alu0_immediate_o;
    wire logic [5:0]                alu0_dest_o;
    wire logic [1:0]                alu0_hint_o;
    wire logic [4:0]                alu0_rob_i;
    wire logic [6:0]                alu1_opcode_o;
    wire logic [5:0]                alu1_ins_type;
    wire logic                      alu1_imm_o;
    wire logic [31:0]               alu1_immediate_o;
    wire logic [5:0]                alu1_dest_o;
    wire logic [1:0]                alu1_hint_o;
    wire logic [4:0]                alu1_rob_i;
    iram instructionRAM (cpu_clock_i,ins0_opcode_i, ins0_ins_type, ins0_imm_i, ins0_immediate_i, ins0_dest_i,ins0_hint_i, ins0_valid, ins1_opcode_i, ins1_ins_type, ins1_imm_i,
    ins1_immediate_i, ins1_dest_i,ins1_hint_i, ins1_valid, pack_id, alu0_opcode_o, alu0_ins_type, alu0_imm_o, alu0_immediate_o, alu0_dest_o, alu0_hint_o,alu0_rob_i, alu1_opcode_o,
    alu1_ins_type,  alu1_imm_o, alu1_immediate_o, alu1_dest_o, alu1_hint_o, alu1_rob_i);
    wire logic [3:0]            pack_i = alu0_rob_i[4:1];
    wire logic [29:0]           pc_o;
    wire logic  [1:0]           bm_pred_o;
    wire logic  [1:0]           btype_o;
    wire logic                  btb_vld_o;
    wire logic  [29:0]          btb_target_o;
    wire logic                  btb_way_o;
    wire logic                  btb_idx_o;
    binfo branchINFO (cpu_clock_i, rn_pc_i, rn_bm_pred_i, rn_btype_i, rn_btb_vld_i, rn_btb_target_i, rn_btb_way_i, rn_btb_idx_i, rn_btb_pack, rn_btb_wen,
    pack_i, pc_o, bm_pred_o, btype_o, btb_vld_o, btb_target_o, btb_way_o, btb_idx_o);
    logic               alu2_vld;
    logic      [17:0]   alu2_data;
    logic               alu_vld;
    logic      [17:0]   alu_data;
    wire [5:0] wkp_alu0; wire wkp_alu0_v; wire [5:0] wkp_alu1; wire wkp_alu1_v;
    unifiedIntQueue uiq0 (cpu_clock_i, flush_i, p0_data_i, p0_vld_i, p0_rs1_vld_i, p0_rs2_vld_i, p0_rs1_rdy, p0_rs2_rdy, p1_data_i, p1_vld_i, p1_rs1_vld_i, p1_rs2_vld_i, 
    p1_rs1_rdy, p1_rs2_rdy, p0_busy_o, p1_busy_o,alu2_vld, alu2_data, alu_vld, alu_data, wkp_alu0, wkp_alu0_v, wkp_alu1, wkp_alu1_v, eu2_dest, eu2_v);
    wire logic [31:0]                       bnch_operand_1;
    wire logic [31:0]                       bnch_operand_2;
    wire logic [31:0]                       bnch_offset;
    wire logic [29:0]                       bnch_pc;
    wire logic                              bnch_auipc;
    wire logic                              bnch_call;
    wire logic                              bnch_ret;
    wire logic                              bnch_jal;
    wire logic                              bnch_jalr;
    wire logic [2:0]                        bnch_bnch_cond;
    wire logic [5:0]                        bnch_rob_id_o;
    wire logic [5:0]                        bnch_dest_o;
    wire logic  [1:0]                       bnch_bm_pred_o;
    wire logic  [1:0]                       bnch_btype_o;
    wire logic                              bnch_btb_vld_o;
    wire logic  [29:0]                      bnch_btb_target_o;
    wire logic                              bnch_btb_way_o;
    wire logic                              bnch_valid_o;
    wire logic [31:0]                       alu0_a;
    wire logic [31:0]                       alu0_b;
    wire logic [6:0]                        alu0_opc;
    wire logic [4:0]                        alu0_rob_id_o;
    wire logic [5:0]                        alu0_dest;
    wire logic                              alu0_valid;
    wire logic [31:0]                       valu0_a;
    wire logic [31:0]                       valu0_b;
    wire logic [6:0]                        valu0_opc;
    wire logic [4:0]                        valu0_rob_id_o;
    wire logic [5:0]                        valu0_dest;
    wire logic                              valu0_valid;
    EX00 port0 (cpu_clock_i, flush_i, alu_data, alu_vld, ex00_rs1_o, ex00_rs2_o, ex00_rs1_data_i, ex00_rs2_data_i, alu0_rob_i, alu0_opcode_o,alu0_ins_type,
    alu0_imm_o,alu0_immediate_o,alu0_dest_o, alu0_hint_o,pc_o, bm_pred_o,btype_o,btb_vld_o,btb_target_o,btb_way_o,btb_idx_o, bnch_operand_1,bnch_operand_2, 
    bnch_offset, bnch_pc, bnch_auipc,bnch_call, bnch_ret, bnch_jal, bnch_jalr, bnch_bnch_cond, bnch_rob_id_o,bnch_dest_o,bnch_bm_pred_o,bnch_btype_o,bnch_btb_vld_o,
    bnch_btb_target_o,bnch_btb_way_o, bnch_valid_o,alu0_a,alu0_b,alu0_opc,alu0_rob_id_o,alu0_dest,alu0_valid,valu0_a,valu0_b,valu0_opc,valu0_rob_id_o,valu0_dest,valu0_valid,wkp_alu0, wkp_alu0_v);
    wire logic [31:0]               alu0_out_result;
    wire logic [4:0]                alu0_out_rob_id_o;
    wire logic                      alu0_out_wb_valid_o;
    wire logic [5:0]                alu0_out_dest_o;
    wire logic                      alu0_out_valid_o;
    alu alu0 (cpu_clock_i, flush_i, alu0_a, alu0_b, alu0_opc, alu0_rob_id_o, alu0_dest, alu0_valid, alu0_out_result,alu0_out_rob_id_o,alu0_out_wb_valid_o,
    alu0_out_dest_o,alu0_out_valid_o);
    wire logic [31:0]               valu0_out_result;
    wire logic [4:0]                valu0_out_rob_id_o;
    wire logic                      valu0_out_wb_valid_o;
    wire logic [5:0]                valu0_out_dest_o;
    wire logic                      valu0_out_valid_o;
    ivalu ivalu0 (cpu_clock_i, flush_i, valu0_a, valu0_b, valu0_opc, valu0_rob_id_o, valu0_dest, valu0_valid, valu0_out_result,valu0_out_rob_id_o,valu0_out_wb_valid_o,
    valu0_out_dest_o,valu0_out_valid_o);
    wire logic  [31:0]                   brnch_out_result_o;
    wire logic                           brnch_out_wb_valid_o;
    wire logic  [5:0]                    brnch_out_wb_dest_o;
    wire logic                           brnch_out_res_valid_o;
    wire logic [5:0]                     brnch_out_rob_o;
    wire logic                           brnch_out_rcu_excp_o;
    wire logic  [29:0]                   brnch_out_c1_btb_vpc_o;
    wire logic  [31:0]                   brnch_out_c1_btb_target_o;
    wire logic  [1:0]                    brnch_out_c1_cntr_pred_o;
    wire logic                           brnch_out_c1_bnch_tkn_o;
    wire logic  [1:0]                    brnch_out_c1_bnch_type_o;
    wire logic                           brnch_out_c1_bnch_present_o;
    wire logic                           brnch_out_c1_btb_way_o;
    wire logic                           brnch_out_c1_btb_bm_mod_o;
    wire logic                           brnch_out_c1_call_affirm_o;
    wire logic                           brnch_out_c1_ret_affirm_o;
    branchUnit bu0 (cpu_clock_i, flush_i, bnch_operand_1, bnch_operand_2, bnch_offset, bnch_pc, bnch_auipc, bnch_call, bnch_ret,bnch_jal, bnch_jalr, bnch_bnch_cond,
    bnch_rob_id_o, bnch_dest_o, bnch_bm_pred_o, bnch_btype_o, bnch_btb_vld_o, bnch_btb_target_o, bnch_btb_way_o, bnch_valid_o, brnch_out_result_o,
    brnch_out_wb_valid_o, brnch_out_wb_dest_o, brnch_out_res_valid_o, brnch_out_rob_o, brnch_out_rcu_excp_o, brnch_out_c1_btb_vpc_o, brnch_out_c1_btb_target_o,
    brnch_out_c1_cntr_pred_o, brnch_out_c1_bnch_tkn_o, brnch_out_c1_bnch_type_o, brnch_out_c1_bnch_present_o, brnch_out_c1_btb_way_o, brnch_out_c1_btb_bm_mod_o,brnch_out_c1_call_affirm_o,
    brnch_out_c1_ret_affirm_o);
    EX02 wb0 (flush_i, alu0_out_result,alu0_out_rob_id_o,alu0_out_wb_valid_o,alu0_out_dest_o,alu0_out_valid_o, valu0_out_result,valu0_out_rob_id_o,valu0_out_wb_valid_o,valu0_out_dest_o,valu0_out_valid_o,brnch_out_result_o,
    brnch_out_wb_valid_o, brnch_out_wb_dest_o, brnch_out_res_valid_o, brnch_out_rob_o, brnch_out_rcu_excp_o, brnch_out_c1_btb_vpc_o, brnch_out_c1_btb_target_o,
    brnch_out_c1_cntr_pred_o, brnch_out_c1_bnch_tkn_o, brnch_out_c1_bnch_type_o, brnch_out_c1_bnch_present_o, brnch_out_c1_btb_way_o, brnch_out_c1_btb_bm_mod_o, brnch_out_c1_call_affirm_o,
    brnch_out_c1_ret_affirm_o,p0_we_data,
    p0_we_dest, p0_wen, excp_rob, excp_code, excp_valid, c1_btb_vpc_o, c1_btb_target_o, c1_cntr_pred_o, c1_bnch_tkn_o, c1_bnch_type_o, c1_bnch_present_o,c1_call_affirm_o,
    c1_ret_affirm_o, wb_btb_way_o, 
    wb_btb_bm_mod_o, alu0_rob_id, alu0_complete);
    wire logic [31:0]                       alu1_a;
    wire logic [31:0]                       alu1_b;
    wire logic [6:0]                        alu1_opc;
    wire logic [4:0]                        alu1_rob_id_o;
    wire logic [5:0]                        alu1_dest;
    wire logic                              alu1_valid;
    wire logic [31:0]                       valu1_a;
    wire logic [31:0]                       valu1_b;
    wire logic [6:0]                        valu1_opc;
    wire logic [4:0]                        valu1_rob_id_o;
    wire logic [5:0]                        valu1_dest;
    wire logic                              valu1_valid;
    EX10 port1 (cpu_clock_i, flush_i, alu2_data, alu2_vld, ex10_rs1_o, ex10_rs2_o, ex10_rs1_data_i, ex10_rs2_data_i, alu1_rob_i, alu1_opcode_o, alu1_imm_o,
    alu1_immediate_o, alu1_dest_o,alu1_ins_type[5],alu1_ins_type[3],alu1_a, alu1_b, alu1_opc, alu1_rob_id_o,  alu1_dest, alu1_valid,valu1_a,valu1_b,valu1_opc,valu1_rob_id_o,valu1_dest,valu1_valid);
    wire logic [31:0] alu1_out_result;
    wire logic [4:0]  alu1_out_rob_id_o;
    wire logic        alu1_out_wb_valid_o;
    wire logic [5:0]  alu1_out_dest;
    wire logic        alu1_out_valid_o;
    alu alu1 (cpu_clock_i, flush_i, alu1_a, alu1_b, alu1_opc, alu1_rob_id_o,  alu1_dest, alu1_valid, alu1_out_result, alu1_out_rob_id_o, alu1_out_wb_valid_o, 
    alu1_out_dest, alu1_out_valid_o);
    wire logic [31:0] valu1_out_result;
    wire logic [4:0]  valu1_out_rob_id_o;
    wire logic        valu1_out_wb_valid_o;
    wire logic [5:0]  valu1_out_dest;
    wire logic        valu1_out_valid_o;
    ivalu ivalu1 (cpu_clock_i, flush_i, valu1_a, valu1_b, valu1_opc, valu1_rob_id_o,  valu1_dest, valu1_valid, valu1_out_result, valu1_out_rob_id_o, valu1_out_wb_valid_o, 
    valu1_out_dest, valu1_out_valid_o);
    EX12 wb1 (flush_i, alu1_out_result,alu1_out_rob_id_o,alu1_out_wb_valid_o,alu1_out_dest,alu1_out_valid_o,valu1_out_result,    valu1_out_rob_id_o,    valu1_out_wb_valid_o,    valu1_out_dest,    valu1_out_valid_o, p1_we_data, p1_we_dest, p1_wen, alu1_rob_id, alu1_complete);
    assign wkp_alu1 = valu1_valid ? valu1_dest : alu1_dest; assign wkp_alu1_v = valu1_valid|alu1_valid;
    assign alu0_reg_ready = wkp_alu0_v; assign alu0_reg_dest = wkp_alu0;
    assign alu1_reg_ready = wkp_alu1_v; assign alu1_reg_dest = wkp_alu1;
endmodule
