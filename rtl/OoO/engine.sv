module engine (
    input   wire logic                              cpu_clock_i,
    input   wire logic                              ins0_port_i,
    input   wire logic                              ins0_dnagn_i,
    input   wire logic [5:0]                        ins0_alu_type_i,
    input   wire logic [6:0]                        ins0_alu_opcode_i,
    input   wire logic                              ins0_alu_imm_i,
    input   wire logic [4:0]                        ins0_ios_type_i,
    input   wire logic [2:0]                        ins0_ios_opcode_i,
    input   wire logic [3:0]                        ins0_special_i,
    input   wire logic [4:0]                        ins0_rs1_i,
    input   wire logic [4:0]                        ins0_rs2_i,
    input   wire logic [4:0]                        ins0_dest_i,
    input   wire logic [31:0]                       ins0_imm_i,
    input   wire logic [2:0]                        ins0_reg_props_i,
    input   wire logic                              ins0_dnr_i,
    input   wire logic                              ins0_mov_elim_i,
    input   wire logic                              ins0_excp_valid_i,
    input   wire logic [3:0]                        ins0_excp_code_i,
    input   wire logic                              ins1_port_i,
    input   wire logic                              ins1_dnagn_i,
    input   wire logic [5:0]                        ins1_alu_type_i,
    input   wire logic [6:0]                        ins1_alu_opcode_i,
    input   wire logic                              ins1_alu_imm_i,
    input   wire logic [4:0]                        ins1_ios_type_i,
    input   wire logic [2:0]                        ins1_ios_opcode_i,
    input   wire logic [3:0]                        ins1_special_i,
    input   wire logic [4:0]                        ins1_rs1_i,
    input   wire logic [4:0]                        ins1_rs2_i,
    input   wire logic [4:0]                        ins1_dest_i,
    input   wire logic [31:0]                       ins1_imm_i,
    input   wire logic [2:0]                        ins1_reg_props_i,
    input   wire logic                              ins1_dnr_i,
    input   wire logic                              ins1_mov_elim_i,
    input   wire logic                              ins1_excp_valid_i,
    input   wire logic [3:0]                        ins1_excp_code_i,
    input   wire logic                              ins1_valid_i,
    input   wire logic [29:0]                       insbundle_pc_i,
    input   wire logic [1:0]                        btb_btype_i,
    input   wire logic [1:0]                        btb_bm_pred_i,
    input   wire logic [29:0]                       btb_target_i,
    input   wire logic                              btb_vld_i,
    input   wire logic                              btb_idx_i,
    input   wire logic                              btb_way_i,
    input   wire logic                              valid_i,
    output  wire logic                              rn_busy_o,
    output  wire logic [6:0]                        ms_ins0_opcode_o,
    output  wire logic [5:0]                        ms_ins0_ins_type,
    output  wire logic                              ms_ins0_imm_o,
    output  wire logic [31:0]                       ms_ins0_immediate_o,
    output  wire logic [5:0]                        ms_ins0_dest_o,
    output  wire logic                              ms_ins0_valid,
    output  wire logic [6:0]                        ms_ins1_opcode_o,
    output  wire logic [5:0]                        ms_ins1_ins_type,
    output  wire logic                              ms_ins1_imm_o,
    output  wire logic [31:0]                       ms_ins1_immediate_o,
    output  wire logic [5:0]                        ms_ins1_dest_o,
    output  wire logic                              ms_ins1_valid,
    output  wire logic [3:0]                        ms_pack_id,
    output  wire logic [29:0]                       ms_rn_pc_o,
    output  wire logic  [1:0]                       ms_rn_bm_pred_o,
    output  wire logic  [1:0]                       ms_rn_btype_o,
    output  wire logic                              ms_rn_btb_vld_o,
    output  wire logic  [29:0]                      ms_rn_btb_target_o,
    output  wire logic                              ms_rn_btb_way_o,
    output  wire logic                              ms_rn_btb_idx_o,
    output  wire logic [3:0]                        ms_rn_btb_pack,
    output  wire logic                              ms_rn_btb_wen,
    output  wire logic [18:0]                       ms_p0_data_o,
    output  wire logic                              ms_p0_vld_o,
    output  wire logic                              ms_p0_rs1_vld_o,
    output  wire logic                              ms_p0_rs2_vld_o,
    output  wire logic                              ms_p0_rs1_rdy,
    output  wire logic                              ms_p0_rs2_rdy,
    output  wire logic [18:0]                       ms_p1_data_o,
    output  wire logic                              ms_p1_vld_o,
    output  wire logic                              ms_p1_rs1_vld_o,
    output  wire logic                              ms_p1_rs2_vld_o,
    output  wire logic                              ms_p1_rs1_rdy,
    output  wire logic                              ms_p1_rs2_rdy,
    input   wire logic                              ms_p0_busy_i,
    input   wire logic                              ms_p1_busy_i,

    // memory System    
    output  wire logic                              memSys_renamer_pkt_vld_o,
    output  wire logic [5:0]                        memSys_pkt0_rs1_o,
    output  wire logic [5:0]                        memSys_pkt0_rs2_o,
    output  wire logic [5:0]                        memSys_pkt0_dest_i,
    output  wire logic [31:0]                       memSys_pkt0_immediate_o,
    output  wire logic [4:0]                        memSys_pkt0_ios_type_o,
    output  wire logic [2:0]                        memSys_pkt0_ios_opcode_o,
    output  wire logic [4:0]                        memSys_pkt0_rob_o,
    output  wire logic                              memSys_pkt0_vld_o,
    output  wire logic [5:0]                        memSys_pkt1_rs1_o,
    output  wire logic [5:0]                        memSys_pkt1_rs2_o,
    output  wire logic [5:0]                        memSys_pkt1_dest_o,
    output  wire logic [31:0]                       memSys_pkt1_immediate_o,
    output  wire logic [4:0]                        memSys_pkt1_ios_type_o,
    output  wire logic [2:0]                        memSys_pkt1_ios_opcode_o,
    output  wire logic                              memSys_pkt1_vld_o,
    input   wire logic                              memSys_full,
    input   wire logic                              cpm,
    input   wire logic                              mie,
    input   wire logic [2:0]                        machine_interrupts,

    input   wire logic [4:0]                        alu0_rob_slot_i,
    input   wire logic                              alu0_rob_complete_i,

    input   wire logic [4:0]                        alu1_rob_slot_i,
    input   wire logic                              alu1_rob_complete_i,

    input   wire logic [4:0]                        agu0_rob_slot_i,
    input   wire logic                              agu0_rob_complete_i,

    input   wire logic [4:0]                        ldq_rob_slot_i,
    input   wire logic                              ldq_rob_complete_i,

    input   wire logic                              alu0_reg_ready,
    input   wire logic [5:0]                        alu0_reg_dest,
    input   wire logic                              alu1_reg_ready,
    input   wire logic [5:0]                        alu1_reg_dest,

    output  wire logic                              stb_c0,
    output  wire logic                              stb_c1,
    input   wire logic                              stb_emp,

    input   wire logic                              alu_excp_i,
    input   wire logic [4:0]                        alu_excp_code_i,
    input   wire logic [5:0]                        rob_i,
    input   wire logic [29:0]                       c1_btb_vpc_i,
    input   wire logic [29:0]                       c1_btb_target_i,
    input   wire logic [1:0]                        c1_cntr_pred_i,
    input   wire logic                              c1_bnch_tkn_i,
    input   wire logic [1:0]                        c1_bnch_type_i,
    input   wire logic                              c1_bnch_present_i,

    input   wire logic [5:0]                        completed_rob_id,
    input   wire logic [4:0]                        exception_code_i,
    input   wire logic [31:0]                       exception_addr,
    input   wire logic                              exception_i,

    input   wire logic                              icache_idle,
    input   wire logic                              mem_block_i,
    output  wire logic                              icache_flush,
    output  wire logic                              flush,
    output       logic [29:0]                       flush_address,

    output  wire logic                              rcu_block,

    output  wire logic [4:0]                        oldest_instruction,
    output  wire logic                              rename_flush_o,

    output  wire logic                              ins_commit0,
    output  wire logic                              ins_commit1,
    output  wire logic                              mret,    
    output  wire logic                              take_exception,
    output  wire logic                              take_interrupt,
    output  wire logic [29:0]                       tmu_epc_o,
    output  wire logic [31:0]                       tmu_mtval_o,
    output  wire logic [3:0]                        tmu_mcause_o,
    input   wire logic [29:0]                       mepc_i,
    input   wire logic [31:0]                       mtvec_i,

    output  wire logic [29:0]                       c1_btb_vpc_o, 
    output  wire logic [29:0]                       c1_btb_target_o, 
    output  wire logic [1:0]                        c1_cntr_pred_o,
    output  wire logic                              c1_bnch_tkn_o,
    output  wire logic [1:0]                        c1_bnch_type_o,
    output  wire logic                              c1_btb_mod_o,

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
    output      logic [31:0]            p5_rd_datas,

    input  wire logic [5:0]    r4_vec_indx,
    output  wire logic          r4,
    input  wire logic [5:0]    r5_vec_indx,
    output  wire logic          r5
);
    wire rename_flush = flush;
    reg [5:0] c0 = 6'd0; reg [5:0] c1 = 6'd1; reg [5:0] c2 = 6'd2; reg [5:0] c3 = 6'd3;
    always_ff @(posedge cpu_clock_i) begin
        if (rename_flush) begin
            c0 <= c0+4; c1 <= c1+4; c2 <= c2 + 4; c3 <= c3+4;
        end
    end
    irf integerRegisterFile (cpu_clock_i, p0_we_i, p0_we_data, p0_we_dest, p1_we_i, p1_we_data, p1_we_dest, p2_we_i, p2_we_data, p2_we_dest, p0_rd_src, p0_rd_datas, p1_rd_src,
    p1_rd_datas, p2_rd_src, p2_rd_datas, p3_rd_src, p3_rd_datas, p4_rd_src, p4_rd_datas, p5_rd_src, p5_rd_datas);
    wire logic [5:0]    p0_vec_indx;
    wire logic          p0_busy_vld;
    wire logic [5:0]    p1_vec_indx;
    wire logic          p1_free_vld = rename_flush;
    wire logic          p1_busy_vld;
    wire logic [5:0]    p2_vec_indx = rename_flush ? c1 : alu0_reg_dest;
    wire logic          p2_free_vld = rename_flush|alu0_reg_ready;
    wire logic [5:0]    p3_vec_indx = rename_flush ? c2 : alu1_reg_dest;
    wire logic          p3_free_vld = rename_flush|alu1_reg_ready;
    wire logic [5:0]    p4_vec_indx = rename_flush ? c3:p2_we_dest;
    wire logic          p4_free_vld = rename_flush|p2_we_i;
    wire logic [5:0]    r0_vec_indx;
    wire logic          r0;
    wire logic [5:0]    r1_vec_indx;
    wire logic          r1;
    wire logic [5:0]    r2_vec_indx;
    wire logic          r2;
    wire logic [5:0]    r3_vec_indx;
    wire logic          r3;
    rst rst (cpu_clock_i, p0_vec_indx,p0_busy_vld,rename_flush ? c0 : p1_vec_indx,p1_free_vld,p1_busy_vld,p2_vec_indx,p2_free_vld,p3_vec_indx,p3_free_vld,p4_vec_indx,p4_free_vld,
    r0_vec_indx,r0,r1_vec_indx,r1,r2_vec_indx,r2,r3_vec_indx,r3,r4_vec_indx,r4,r5_vec_indx,r5);
    wire logic          i_wr_en0;
    wire logic [5:0]    i_wr_data0;
    wire logic          o_full0;
    wire logic          i_wr_en1;
    wire logic [5:0]    i_wr_data1;
    wire logic          o_full1;
    wire logic          i_rd0;
    logic [5:0]         o_rd_data0;
    wire logic          o_empty0;
    wire logic          i_rd1;
    logic [5:0]         o_rd_data1;
    wire logic          o_empty1;
    freelist freelist (cpu_clock_i, i_wr_en0,i_wr_data0,o_full0,i_wr_en1,i_wr_data1,o_full1,i_rd0,o_rd_data0,o_empty0,i_rd1,o_rd_data1,o_empty1);
    wire logic [4:0]            rob0_status;
    wire logic                  commit0;
    wire logic                  rob0_status_o;
    wire logic [4:0]            rob1_status;
    wire logic                  commit1;
    wire logic                  rob1_status_o;
    ciff ciff (cpu_clock_i, flush, alu0_rob_slot_i, alu0_rob_complete_i, alu1_rob_slot_i, alu1_rob_complete_i, agu0_rob_slot_i,
    agu0_rob_complete_i, ldq_rob_slot_i, ldq_rob_complete_i, rob0_status, commit0, rob0_status_o, rob1_status, commit1, rob1_status_o);
    wire logic [29:0] packet_pc;
    wire logic        ins0_is_mov_elim;
    wire logic        ins0_register_allocated;
    wire logic [4:0]  ins0_arch_reg;
    wire logic [5:0]  ins0_old_preg;
    wire logic [5:0]  ins0_new_preg;
    wire logic [3:0]  ins0_excp_code;
    wire logic        ins0_excp_valid;
    wire logic [3:0]  ins0_special;
    wire logic        ins0_is_store;
    wire logic        ins1_is_mov_elim;
    wire logic        ins1_register_allocated;
    wire logic [4:0]  ins1_arch_reg;
    wire logic [5:0]  ins1_old_preg;
    wire logic [5:0]  ins1_new_preg;
    wire logic [3:0]  ins1_excp_code;
    wire logic        ins1_excp_valid;
    wire logic [3:0]  ins1_special;
    wire logic        ins1_is_store;
    wire logic        ins1_valid;
    wire logic        push_packet;
    wire logic        rcu_busy;
    wire logic [4:0]  rcu_pack;
    wire logic [4:0]  arch_reg0;
    wire logic [4:0]  arch_reg1;
    wire logic [5:0]  phys_reg0;
    wire logic [5:0]  phys_reg1;

    rename renamer (cpu_clock_i, flush, ins0_port_i, ins0_dnagn_i, ins0_alu_type_i, ins0_alu_opcode_i, ins0_alu_imm_i, ins0_ios_type_i, ins0_ios_opcode_i, ins0_special_i, 
    ins0_rs1_i, ins0_rs2_i, ins0_dest_i, ins0_imm_i, ins0_reg_props_i, ins0_dnr_i, ins0_mov_elim_i, ins0_excp_valid_i, ins0_excp_code_i, ins1_port_i, ins1_dnagn_i, 
    ins1_alu_type_i, ins1_alu_opcode_i, ins1_alu_imm_i, ins1_ios_type_i, ins1_ios_opcode_i, ins1_special_i, ins1_rs1_i, ins1_rs2_i, ins1_dest_i, ins1_imm_i, 
    ins1_reg_props_i, ins1_dnr_i, ins1_mov_elim_i, ins1_excp_valid_i, ins1_excp_code_i, ins1_valid_i, insbundle_pc_i, btb_btype_i, btb_bm_pred_i,
     btb_target_i, btb_vld_i, btb_idx_i, btb_way_i, valid_i, rn_busy_o,  packet_pc,ins0_is_mov_elim,ins0_register_allocated,ins0_arch_reg,ins0_old_preg,
     ins0_new_preg,ins0_excp_code,ins0_excp_valid,ins0_special,ins0_is_store,ins1_is_mov_elim,ins1_register_allocated,ins1_arch_reg,ins1_old_preg,ins1_new_preg,
     ins1_excp_code,ins1_excp_valid,ins1_special,ins1_is_store,ins1_valid,push_packet,rcu_busy,rcu_pack,arch_reg0,arch_reg1,phys_reg0,phys_reg1, ms_ins0_opcode_o,ms_ins0_ins_type,
     ms_ins0_imm_o,ms_ins0_immediate_o,ms_ins0_dest_o,ms_ins0_valid,ms_ins1_opcode_o,ms_ins1_ins_type,ms_ins1_imm_o,ms_ins1_immediate_o,ms_ins1_dest_o,ms_ins1_valid,
     ms_pack_id,ms_rn_pc_o,ms_rn_bm_pred_o,ms_rn_btype_o,ms_rn_btb_vld_o,ms_rn_btb_target_o,ms_rn_btb_way_o,ms_rn_btb_idx_o,ms_rn_btb_pack,
     ms_rn_btb_wen,ms_p0_data_o,ms_p0_vld_o,ms_p0_rs1_vld_o,ms_p0_rs2_vld_o,ms_p0_rs1_rdy,ms_p0_rs2_rdy,ms_p1_data_o,ms_p1_vld_o,ms_p1_rs1_vld_o,ms_p1_rs2_vld_o,
     ms_p1_rs1_rdy,ms_p1_rs2_rdy,ms_p0_busy_i,ms_p1_busy_i,memSys_renamer_pkt_vld_o,memSys_pkt0_rs1_o,memSys_pkt0_rs2_o,memSys_pkt0_dest_i,memSys_pkt0_immediate_o,
     memSys_pkt0_ios_type_o,memSys_pkt0_ios_opcode_o,memSys_pkt0_rob_o,memSys_pkt0_vld_o,memSys_pkt1_rs1_o,memSys_pkt1_rs2_o,memSys_pkt1_dest_o,memSys_pkt1_immediate_o,
     memSys_pkt1_ios_type_o,memSys_pkt1_ios_opcode_o,memSys_pkt1_vld_o,memSys_full, p0_vec_indx,p0_busy_vld,p1_vec_indx, p1_busy_vld, r0_vec_indx,r0,
     r1_vec_indx,r1,r2_vec_indx,r2,r3_vec_indx,r3, i_rd0,o_rd_data0,o_empty0,i_rd1,o_rd_data1,o_empty1);
    retireControlUnit rcu0 (cpu_clock_i, cpm, mie, machine_interrupts, packet_pc, ins0_is_mov_elim, 
    ins0_register_allocated, ins0_arch_reg, ins0_old_preg, ins0_new_preg, ins0_excp_code, ins0_excp_valid, ins0_special, ins0_is_store, ins1_is_mov_elim, 
    ins1_register_allocated, ins1_arch_reg, ins1_old_preg, ins1_new_preg, ins1_excp_code, ins1_excp_valid, ins1_special, ins1_is_store, ins1_valid, push_packet, 
    rcu_busy, rcu_pack, arch_reg0, arch_reg1, phys_reg0, phys_reg1,rob0_status,commit0,rob0_status_o,rob1_status,commit1,rob1_status_o, stb_c0, stb_c1, stb_emp,
    i_wr_en0,i_wr_data0,i_wr_en1,i_wr_data1,alu_excp_i, alu_excp_code_i, rob_i, c1_btb_vpc_i, c1_btb_target_i, c1_cntr_pred_i, c1_bnch_tkn_i, c1_bnch_type_i, c1_bnch_present_i,
    completed_rob_id, exception_code_i, exception_addr, exception_i, icache_idle, mem_block_i, icache_flush, flush, flush_address, rcu_block,
    oldest_instruction, rename_flush_o, ins_commit0, ins_commit1,mret, take_exception, take_interrupt, tmu_epc_o, tmu_mtval_o, tmu_mcause_o, mepc_i, 
    mtvec_i, c1_btb_vpc_o,  c1_btb_target_o,  c1_cntr_pred_o, c1_bnch_tkn_o, c1_bnch_type_o, c1_btb_mod_o
    );
endmodule
