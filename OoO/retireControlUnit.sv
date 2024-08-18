// RCU
/**
**/
module retireControlUnit (
    input   wire logic                              cpu_clock_i,

    input   wire logic                              cpm,
    input   wire logic                              mie,
    input   wire logic [2:0]                        machine_interrupts,

    input   wire logic [29:0]                       packet_pc,
    input   wire logic                              ins0_is_mov_elim,
    input   wire logic                              ins0_register_allocated,
    input   wire logic [4:0]                        ins0_arch_reg,
    input   wire logic [5:0]                        ins0_old_preg,
    input   wire logic [5:0]                        ins0_new_preg,
    input   wire logic [3:0]                        ins0_excp_code,
    input   wire logic                              ins0_excp_valid,
    input   wire logic [3:0]                        ins0_special,
    input   wire logic                              ins0_is_store,
    input   wire logic                              ins1_is_mov_elim,
    input   wire logic                              ins1_register_allocated,
    input   wire logic [4:0]                        ins1_arch_reg,
    input   wire logic [5:0]                        ins1_old_preg,
    input   wire logic [5:0]                        ins1_new_preg,
    input   wire logic [3:0]                        ins1_excp_code,
    input   wire logic                              ins1_excp_valid,
    input   wire logic [3:0]                        ins1_special,
    input   wire logic                              ins1_is_store,
    input   wire logic                              ins1_valid,
    input   wire logic                              push_packet,
    output  wire logic                              rcu_busy,
    output  wire logic [4:0]                        rcu_pack,
    output  wire logic [4:0]                        arch_reg0,
    output  wire logic [4:0]                        arch_reg1,
    output  wire logic [5:0]                        phys_reg0,
    output  wire logic [5:0]                        phys_reg1,
    // Complete instruction bitvector
    output  wire logic [4:0]                        rob0_status,
    output  wire logic                              commit0,
    input   wire logic                              rob0_status_i,
    output  wire logic [4:0]                        rob1_status,
    output  wire logic                              commit1,
    input   wire logic                              rob1_status_i,
    // Store Queue/Buffer
    output  wire logic                              sqb_commit0,
    output  wire logic                              sqb_commit1,
    input   wire logic                              sqb_empty,
    // free list
    output  wire logic                              wr_en0,
    output  wire logic [5:0]                        wr_data0,
    output  wire logic                              wr_en1,
    output  wire logic [5:0]                        wr_data1,

    // exceptions
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
    
    output  wire logic                              flush_o,
    output       logic [29:0]                       flush_address,

    output  wire logic                              rcu_block,

    output  wire logic [4:0]                        oldest_instruction,
    output  wire logic                              rename_flush_o,

    output  wire logic                              ins_commit0,
    output  wire logic                              ins_commit1,
    // exception returns
    output  wire logic                              mret,
    // exception handling           
    output  wire logic                              take_exception,
    output  wire logic                              take_interrupt,
    output  wire logic [29:0]                       tmu_epc_o,
    output  wire logic [31:0]                       tmu_mtval_o,
    output  wire logic [3:0]                        tmu_mcause_o,
    input   wire logic [29:0]                       mepc_i,
    input   wire logic [31:0]                       mtvec_i,

    output  wire logic [29:0]                       c1_btb_vpc_o, //! SIP PC
    output  wire logic [29:0]                       c1_btb_target_o, //! SIP Target **if** taken
    output  wire logic [1:0]                        c1_cntr_pred_o, //! Bimodal counter prediction,
    output  wire logic                              c1_bnch_tkn_o, //! Branch taken this cycle
    output  wire logic [1:0]                        c1_bnch_type_o,
    output  wire logic                              c1_btb_mod_o
);
    wire full;
    wire empty;
    wire packet_pop;
    wire [4:0] rd_ptr; wire [4:0] wr_ptr;
    /*verilator lint_off UNUSEDSIGNAL*/
    wire logic [29:0] cpacket_pc;
    /*verilator lint_on UNUSEDSIGNAL*/
    wire logic        cins0_is_mov_elim;
    wire logic        cins0_register_allocated;
    wire logic [4:0]  cins0_arch_reg;
    wire logic [5:0]  cins0_old_preg;
    wire logic [5:0]  cins0_new_preg;
    wire logic [3:0]  cins0_excp_code;
    wire logic        cins0_excp_valid;
    wire logic [3:0]  cins0_special;
    wire logic        cins0_is_store;
    wire logic        cins1_is_mov_elim;
    wire logic        cins1_register_allocated;
    wire logic [4:0]  cins1_arch_reg;
    wire logic [5:0]  cins1_old_preg;
    wire logic [5:0]  cins1_new_preg;
    wire logic [3:0]  cins1_excp_code;
    wire logic        cins1_excp_valid;
    wire logic [3:0]  cins1_special;
    wire logic        cins1_is_store;
    wire logic        cins1_valid;
    wire commit_ins0; wire commit_ins1; wire safe_to_free0; wire safe_to_free1;
    assign commit0 = commit_ins0; assign commit1 = commit_ins1;
    reg partial_retire;
    reg [4:0] recoveryCounter0 = 5'b00000;
    reg [4:0] recoveryCounter1 = 5'b00001;
    reg [31:0] relavant_address;
    reg [4:0]  exception_code;
    reg [5:0]  exception_rob;
    reg        exception_valid = 0;
    reg [29:0] c1_btb_vpc;
    reg [29:0] c1_btb_target;
    reg [1:0]  c1_cntr_pred;
    reg        c1_bnch_tkn;
    reg [1:0]  c1_bnch_type;
    reg        c1_bnch_present = 0;
    localparam Normal = 3'b000; localparam ReclaimAndRecover = 3'b111; // flush held high for 16 cycles
    localparam WipeInstructionCache = 3'b001; localparam WaitForInterrupt = 3'b010;
    localparam Await = 3'b110;
    reg [2:0] retire_control_state = Normal;

    sfifospecial #(.DW(89)) instruction_information_buffer (
        cpu_clock_i, 1'b0, push_packet&!full, {packet_pc, ins0_is_mov_elim, ins0_register_allocated, ins0_arch_reg, ins0_old_preg, ins0_new_preg, ins0_excp_code,
        ins0_excp_valid, ins0_special, ins0_is_store, ins1_is_mov_elim, ins1_register_allocated, ins1_arch_reg, ins1_old_preg, ins1_new_preg, ins1_excp_code, ins1_excp_valid,
        ins1_special, ins1_is_store, ins1_valid}, full, packet_pop, {cpacket_pc,cins0_is_mov_elim,cins0_register_allocated,cins0_arch_reg,cins0_old_preg,cins0_new_preg,cins0_excp_code,
        cins0_excp_valid,cins0_special,cins0_is_store,cins1_is_mov_elim,cins1_register_allocated,cins1_arch_reg,cins1_old_preg,cins1_new_preg,cins1_excp_code,
        cins1_excp_valid,cins1_special,cins1_is_store,cins1_valid}, empty, rd_ptr, wr_ptr);
    assign rob0_status = {rd_ptr[3:0],1'b0};
    assign rob1_status = {rd_ptr[3:0],1'b1};
    assign rcu_pack = wr_ptr;
    assign arch_reg0 = recoveryCounter0; assign arch_reg1 = recoveryCounter1;
    assign sqb_commit0 = cins0_is_store&commit_ins0;
    assign sqb_commit1 = (cins1_is_store&commit_ins1);
    wire altcommit, altcommit0, altcommit1;
    assign altcommit0 = altcommit&!partial_retire; assign altcommit1 = altcommit&partial_retire;
    crmt architectural_register_map (cpu_clock_i, arch_reg0, phys_reg0, arch_reg1, phys_reg1, cins0_arch_reg, cins0_new_preg, 
    (commit_ins0|altcommit0)&(cins0_is_mov_elim|cins0_register_allocated)&(cins0_arch_reg!=0),cins1_arch_reg, cins1_new_preg,
    (commit_ins1|altcommit1)&(cins1_is_mov_elim|cins1_register_allocated)&(cins1_arch_reg!=0));
    rrt register_reference_counters (cpu_clock_i, cins0_new_preg, (commit_ins0|altcommit0)&(cins0_is_mov_elim|cins0_register_allocated),
    cins1_new_preg, (commit_ins1|altcommit1)&(cins1_is_mov_elim|cins1_register_allocated), cins0_old_preg, (commit_ins0|altcommit0)&(cins0_is_mov_elim|cins0_register_allocated),
    cins1_old_preg, (commit_ins1|altcommit1)&(cins1_is_mov_elim|cins1_register_allocated), safe_to_free0, safe_to_free1);
    assign rcu_busy = full;
    wire [29:0] currentPC = cpacket_pc[0] ? cpacket_pc : {cpacket_pc[29:1], partial_retire};
    wire [29:0] pcPlus4 = currentPC + 29'd1; // used in special types CSRRW, SFENCE, FENCE.I
    // Conditions of committing
    assign packet_pop = ((partial_retire&(commit_ins1|altcommit1))|((commit_ins0|altcommit0)&((!cins1_valid)|(commit_ins1))))|(retire_control_state==ReclaimAndRecover);
    assign wr_data0 = retire_control_state==ReclaimAndRecover ? cins0_new_preg : cins0_old_preg;
    assign wr_data1 = retire_control_state==ReclaimAndRecover ? cins1_new_preg : cins1_old_preg;
    assign wr_en0 = retire_control_state==Normal ? safe_to_free0&(cins0_register_allocated|cins0_is_mov_elim)&(commit_ins0|altcommit0)&!(cins0_old_preg==0) : (retire_control_state==ReclaimAndRecover)
    &&cins0_register_allocated&&!empty&&!partial_retire;
    assign wr_en1 = retire_control_state==Normal ? safe_to_free1&(cins1_register_allocated|cins1_is_mov_elim)&(commit_ins1|altcommit1)&!(cins1_old_preg==0) : (retire_control_state==ReclaimAndRecover)
    &&cins1_register_allocated&&!empty;
    assign flush_o = retire_control_state==ReclaimAndRecover;
    assign commit_ins0 = (rob0_status_i|cins0_is_mov_elim)&&!empty&&!partial_retire&&!(cins0_excp_valid)&&!(|cins0_special) && (retire_control_state==Normal) && ((rob0_status!=exception_rob[4:0])||!exception_valid) && !rcu_block;
    assign commit_ins1 = (partial_retire|commit_ins0) && ((rob1_status_i|cins1_is_mov_elim)&&!empty&&!(cins1_excp_valid)&&!(|cins1_special)) && (retire_control_state==Normal) && ((rob1_status!=exception_rob[4:0])||!exception_valid) && !rcu_block && cins1_valid;
    wire older_alu = exception_rob[5]==rob_i[5] ? rob_i[4:0] < exception_rob[4:0] : rob_i[4:0] > exception_rob[4:0];
    wire oldest_live_excp = !exception_i ? 1'b0: !alu_excp_i ? 1'b1 : completed_rob_id[5]==rob_i[5] ? completed_rob_id[4:0]<rob_i[4:0] :
    completed_rob_id[4:0]>rob_i[4:0]; // 1 when LSU is oldest
    wire [5:0] winner = oldest_live_excp ? completed_rob_id : rob_i;
    wire older_than_current = (!exception_valid||(exception_rob[5]==winner[5] ? winner[4:0]<exception_rob[4:0] : winner[4:0]>exception_rob[4:0]))
    &&(alu_excp_i|exception_i); // 1 when older than current
    always_ff @(posedge cpu_clock_i) begin
        exception_valid <= flush_o ? 1'b0 : exception_valid|(alu_excp_i|exception_i);
        exception_code <= older_than_current ? oldest_live_excp ? exception_code_i : alu_excp_code_i : exception_code;
        exception_rob <= older_than_current ? oldest_live_excp ? completed_rob_id : rob_i : exception_rob;
        relavant_address <= older_than_current&oldest_live_excp ?  exception_addr : relavant_address;
        c1_btb_vpc <= (older_alu|!exception_valid)&&alu_excp_i ? c1_btb_vpc_i : c1_btb_vpc;
        c1_btb_target <= (older_alu|!exception_valid)&&alu_excp_i ? c1_btb_target_i : c1_btb_target;
        c1_cntr_pred <=  (older_alu|!exception_valid)&&alu_excp_i ? c1_cntr_pred_i : c1_cntr_pred;
        c1_bnch_tkn <=  (older_alu|!exception_valid)&&alu_excp_i ? c1_bnch_tkn_i : c1_bnch_tkn;
        c1_bnch_type <=  (older_alu|!exception_valid)&&alu_excp_i ? c1_bnch_type_i : c1_bnch_type;
        c1_bnch_present <=  (older_alu|!exception_valid)&&alu_excp_i ? c1_bnch_present_i : c1_bnch_present;
    end
    wire [3:0] int_type;
    wire interrupt_pending;
    wire logic [3:0]  excp_excp_code = partial_retire ? cins1_excp_code : cins0_excp_code;
    wire logic        excp_excp_valid = partial_retire ? cins1_excp_valid : cins0_excp_valid;
    wire logic [3:0]  excp_special = partial_retire ? cins1_special : cins0_special;
    interrupt_router interrupts (cpm, mie, machine_interrupts, interrupt_pending, int_type);
    wire logic backendException = exception_valid && (partial_retire ? rob1_status==exception_rob[4:0] : rob0_status==exception_rob[4:0]) && !empty;
    assign oldest_instruction = {rd_ptr[3:0], partial_retire};
    assign rcu_block = retire_control_state!=Normal;
    assign rename_flush_o = (retire_control_state==Await) && icache_idle;
    assign ins_commit0 = commit_ins0;
    assign ins_commit1 = commit_ins1;
    assign mret = !interrupt_pending&((excp_special[2]))&(retire_control_state==Normal)&!empty&!mem_block_i&!excp_excp_valid;
    assign take_interrupt = interrupt_pending&&(!empty)&&!mem_block_i&(retire_control_state==Normal);
    assign take_exception = !interrupt_pending&(excp_excp_valid|(backendException&!exception_code[4]))&!mem_block_i&!empty&(retire_control_state==Normal);
    assign tmu_epc_o = currentPC; assign tmu_mcause_o = take_interrupt ? int_type : excp_excp_valid ? excp_excp_code : exception_code[3:0];
    assign tmu_mtval_o = backendException ? relavant_address : excp_excp_code[3:1]==0 ? {currentPC,2'b00} : 0;
    assign altcommit = ((backendException&exception_code[4])||((|excp_special)&&((excp_special[3]&(partial_retire ? rob1_status_i : rob0_status_i))||!excp_special[3])))
    && (retire_control_state==Normal)&!mem_block_i&!empty&!interrupt_pending;
    reg btb_mod;
    // Special[3] == CSR writes
    // Special[2] == MRET
    // Special[1] == FENCE.I
    // Special[0] == WFI
    always_ff @(posedge cpu_clock_i) begin
        case (retire_control_state)
            Normal: begin
                if (interrupt_pending&&(!empty)&&!mem_block_i) begin
                    retire_control_state <= Await;
                    flush_address <= !(|mtvec_i[1:0]) ? mtvec_i[31:2] : {mtvec_i[31:2]} + {26'h0, tmu_mcause_o[3:0]};
                end
                else if ((excp_excp_valid|backendException)&!mem_block_i&!empty) begin
                    retire_control_state <= Await;
                    flush_address <= backendException&exception_code[4] ? c1_btb_target : mtvec_i[31:2];
                end else if ((((|excp_special)&&((excp_special[3]&(partial_retire ? rob1_status_i : rob0_status_i))||!excp_special[3]))&!mem_block_i&!empty)) begin
                    retire_control_state <= excp_special[1] ? WipeInstructionCache : excp_special[0] ? WaitForInterrupt : Await;
                    flush_address <= excp_special[2] ? mepc_i : pcPlus4;
                end
                partial_retire <= partial_retire ? partial_retire&!(commit_ins1|altcommit1) : ((commit_ins0)&!commit_ins1&cins1_valid)|(altcommit0&cins1_valid);
                btb_mod <= exception_code[4]&backendException;
            end
            WipeInstructionCache: begin
                if (icache_idle&&sqb_empty) begin
                    retire_control_state <= Await;
                end
            end
            WaitForInterrupt: begin
                if (interrupt_pending&&(!empty)&&!mem_block_i) begin
                    retire_control_state <= Await;
                    flush_address <= !(|mtvec_i[1:0]) ? mtvec_i[31:2] : {mtvec_i[31:2]} + {26'h0, tmu_mcause_o[3:0]};
                end
            end
            ReclaimAndRecover: begin
                partial_retire <= 0;
                recoveryCounter0 <= recoveryCounter0 + 5'd2;
                recoveryCounter1 <= recoveryCounter1 + 5'd2;
                btb_mod <= 0;
                if (recoveryCounter0==5'd30) begin
                    retire_control_state <= Normal;
                end
            end
            Await: begin
                if (icache_idle) begin
                    retire_control_state <= ReclaimAndRecover;
                end
            end
            default: begin
                retire_control_state <= Normal;
            end
        endcase
    end
    assign icache_flush = icache_idle&&sqb_empty&&(retire_control_state==WipeInstructionCache);
    assign c1_btb_vpc_o = c1_btb_vpc;
    assign c1_btb_target_o = c1_btb_target;
    assign c1_cntr_pred_o = c1_cntr_pred;
    assign c1_bnch_tkn_o = c1_bnch_tkn;
    assign c1_bnch_type_o = c1_bnch_type;
    assign c1_btb_mod_o = (retire_control_state==Await)&&icache_idle&&btb_mod;
endmodule
