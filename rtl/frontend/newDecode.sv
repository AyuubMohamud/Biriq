// SPDX-FileCopyrightText: 2024 Ayuub Mohamud <ayuub.mohamud@outlook.com>
// SPDX-License-Identifier: CERN-OHL-W-2.0

//  -----------------------------------------------------------------------------------------
//  | Copyright (C) Ayuub Mohamud 2024.                                                     |
//  |                                                                                       |
//  | This source describes Open Hardware (RTL) and is licensed under the CERN-OHL-W v2.    |
//  |                                                                                       |
//  | You may redistribute and modify this source and make products using it under          |
//  | the terms of the CERN-OHL-W v2 (https://ohwr.org/cern_ohl_w_v2.txt).                  |
//  |                                                                                       |
//  | This source is distributed WITHOUT ANY EXPRESS OR IMPLIED WARRANTY,                   |
//  | INCLUDING OF MERCHANTABILITY, SATISFACTORY QUALITY AND FITNESS FOR A                  |
//  | PARTICULAR PURPOSE. Please see the CERN-OHL-W v2 for applicable conditions.           |
//  |                                                                                       |
//  | Source location: https://github.com/AyuubMohamud/Biriq                                |
//  |                                                                                       |
//  | As per CERN-OHL-W v2 section 4, should You produce hardware based on this             |
//  | source, You must where practicable maintain the Source Location visible               |
//  | in the same manner as is done within this source.                                     |
//  |                                                                                       |
//  -----------------------------------------------------------------------------------------
module newDecode #(
    parameter ENABLE_PSX = 1,
    parameter ENABLE_C_EXTENSION = 1,
    localparam PC_BITS = ENABLE_C_EXTENSION==1 ? 31 : 30,
    localparam IDX_BITS = ENABLE_C_EXTENSION==1 ? 2 : 1
) (
    input   wire logic                  cpu_clk_i,
    input   wire logic                  flush_i,
    input   wire logic                  current_privlidge,
    input   wire logic                  tw,
    input   wire logic [1:0]            cbie,
    input   wire logic                  cbcfe,
    input   wire logic                  cbze,
    input   wire logic                  icache_idle,
    input   wire logic                  icache_valid_i,
    input   wire logic [31:0]           dec0_instruction_i,
    input   wire logic                  dec0_instruction_is_2_i,
    input   wire logic [31:0]           dec1_instruction_i,
    input   wire logic                  dec1_instruction_is_2_i,
    input   wire logic                  dec1_instruction_valid_i,
    input   wire logic [PC_BITS-1:0]    if2_sip_vpc_i,
    input   wire logic [3:0]            if2_sip_excp_code_i,
    input   wire logic                  if2_sip_excp_vld_i,
    input   wire logic [IDX_BITS-1:0]   if2_btb_index,
    input   wire logic [1:0]            btb_btype_i, //! Branch type: 00 = Cond, 01 = Indirect, 10 - Jump, 11 - Ret
    input   wire logic [1:0]            btb_bm_pred_i, //! Bimodal counter prediction
    input   wire logic [PC_BITS-1:0]    btb_target_i, //! Predicted target if branch is taken
    input   wire logic                  btb_vld_i,
    input   wire logic                  btb_way_i,
    output  wire logic                  busy_o,


    output       logic                  ins0_port_o,
    output       logic                  ins0_dnagn_o,
    output       logic [5:0]            ins0_alu_type_o,
    output       logic [6:0]            ins0_alu_opcode_o,
    output       logic                  ins0_alu_imm_o,
    output       logic [5:0]            ins0_ios_type_o,
    output       logic [2:0]            ins0_ios_opcode_o,
    output       logic [3:0]            ins0_special_o,
    output       logic [4:0]            ins0_rs1_o,
    output       logic [4:0]            ins0_rs2_o,
    output       logic [4:0]            ins0_dest_o,
    output       logic [31:0]           ins0_imm_o,
    output       logic [2:0]            ins0_reg_props_o,
    output       logic                  ins0_dnr_o,
    output       logic                  ins0_mov_elim_o,
    output       logic [1:0]            ins0_hint_o,
    output       logic                  ins0_2byte_o,
    output       logic                  ins0_excp_valid_o,
    output       logic [3:0]            ins0_excp_code_o,
    output       logic                  ins1_port_o,
    output       logic                  ins1_dnagn_o,
    output       logic [5:0]            ins1_alu_type_o,
    output       logic [6:0]            ins1_alu_opcode_o,
    output       logic                  ins1_alu_imm_o,
    output       logic [5:0]            ins1_ios_type_o,
    output       logic [2:0]            ins1_ios_opcode_o,
    output       logic [3:0]            ins1_special_o,
    output       logic [4:0]            ins1_rs1_o,
    output       logic [4:0]            ins1_rs2_o,
    output       logic [4:0]            ins1_dest_o,
    output       logic [31:0]           ins1_imm_o,
    output       logic [2:0]            ins1_reg_props_o,
    output       logic                  ins1_dnr_o,
    output       logic                  ins1_mov_elim_o,
    output       logic [1:0]            ins1_hint_o,
    output       logic                  ins1_2byte_o,
    output       logic                  ins1_excp_valid_o,
    output       logic [3:0]            ins1_excp_code_o,
    output       logic                  ins1_valid_o,
    output       logic [PC_BITS-1:0]    insbundle_pc_o,
    output       logic [1:0]            btb_btype_o,
    output       logic [1:0]            btb_bm_pred_o,
    output       logic [PC_BITS-1:0]    btb_target_o,
    output       logic                  btb_vld_o,
    output       logic [IDX_BITS-1:0]   btb_idx_o,
    output       logic                  btb_way_o,
    output       logic                  valid_o,
    input   wire logic                  rn_busy_i,

    output  wire logic                  branch_correction_flush,
    output  wire logic [PC_BITS-1:0]    branch_correction_pc
);
    wire [63:0] rv_instruction_i_p;
    wire [PC_BITS-1:0] rv_ppc_i;
    wire [PC_BITS-1:0] rv_target; wire [1:0] rv_btype; wire [1:0] rv_bm_pred; wire rv_btb_vld; wire excp_vld; wire [3:0] excp_code;
    wire logic [31:0]           dec0_instruction;
    wire logic                  dec0_instruction_is_2;
    wire logic [31:0]           dec1_instruction;
    wire logic                  dec1_instruction_is_2;
    wire logic                  dec1_instruction_valid;
    reg shutdown_frontend = 0;
    wire rv_valid; wire [IDX_BITS-1:0] btb_idx; wire btb_way;
    skdbf #(.DW(PC_BITS+PC_BITS+78+IDX_BITS)) skidbuffer (
        cpu_clk_i, flush_i|branch_correction_flush, rn_busy_i, {dec0_instruction,
        dec0_instruction_is_2,
        dec1_instruction,
        dec1_instruction_is_2,
        dec1_instruction_valid,rv_ppc_i, rv_target, rv_btype, rv_bm_pred, rv_btb_vld, excp_vld, excp_code,btb_idx,btb_way},
        rv_valid, busy_o, 
        {dec0_instruction_i,
        dec0_instruction_is_2_i,
        dec1_instruction_i,
        dec1_instruction_is_2_i,
        dec1_instruction_valid_i, if2_sip_vpc_i, btb_target_i, btb_btype_i,
        btb_bm_pred_i, btb_vld_i, if2_sip_excp_vld_i, if2_sip_excp_code_i, if2_btb_index,btb_way_i}, icache_valid_i
    );
    assign rv_instruction_i_p[31:0] = dec0_instruction;
    assign rv_instruction_i_p[63:32] = dec1_instruction;
    wire [31:0] rv_instruction_i = rv_instruction_i_p[31:0];
    wire [31:0] rv_instruction_i2 = rv_instruction_i_p[63:32];
    wire [31:0] jalrImmediate = {{20{rv_instruction_i[31]}},rv_instruction_i[31:20]};
    wire [31:0] cmpBranchImmediate = {{20{rv_instruction_i[31]}}, rv_instruction_i[7], rv_instruction_i[30:25], rv_instruction_i[11:8], 1'b0};
    wire [31:0] jalImmediate = {{11{rv_instruction_i[31]}}, rv_instruction_i[31], rv_instruction_i[19:12], rv_instruction_i[20], rv_instruction_i[30:21], 1'b0};
    wire [31:0] auipcImmediate = {rv_instruction_i[31:12], 12'h000};
    wire [31:0] storeImmediate = {{20{rv_instruction_i[31]}}, rv_instruction_i[31:25], rv_instruction_i[11:7]};

    // how to do the instructions
    /**
        ALUs and BU require a code in the form of
        ins_type: 0 = ALU, 1 = JAL, 2 = JALR, 3 = LUI, 4 - AUIPC
        opcode: {instruction[30], instruction[14:12]}
        In Order Scheduler: 
        Loads, Stores, CSRx, Fences and Multiply and Divides
        require a code of 
        ins_type : Load, Store, CSR, Fence, MD
        opcode: {signage, size} (LOADs), {0, size} (Stores), {imm, type} (CSR), {instruction[14:12]} (Mults and Divs)
        Special instructions that force the processor to flush
        FENCE.I
        any CSR write
        MRET
        SRET
        SFENCE.VMA
        -- Instruction Attributes
        rs1, rs2, dest, immediate, uses immediate
        reg_alloc, rs1_valid, rs2_valid
        exception_valid, exception_code
    **/
    wire isLoad = rv_instruction_i[6:2]==5'b00000; 
    wire isStore = rv_instruction_i[6:2]==5'b01000;
    wire load_invalid = &rv_instruction_i[14:13]; //11x is invalid given it is load;
    wire store_invalid = rv_instruction_i[14:12] > 3'b010;
    wire isSystem = rv_instruction_i[6:2] == 5'b11100;
    wire isECALL = rv_instruction_i[31:7] == 0;
    wire isEBREAK = rv_instruction_i[31:7] == 25'b000000000001000000000000;
    wire isMRET = rv_instruction_i[31:7]==25'b0011000000100000000000000;
    wire isWFI =  rv_instruction_i[31:7]==25'b0001000001010000000000000;
    wire isCSRRW = rv_instruction_i[13:12]==2'b01;
    wire isCSRRS = rv_instruction_i[13:12]==2'b10;
    wire isCSRRC = rv_instruction_i[13:12]==2'b11;
    wire csr_imm = rv_instruction_i[14];
    wire isFenceI = rv_instruction_i[31:0]==32'b00000000000000000001000000001111;
    wire isCMO = rv_instruction_i[31:23]==9'd0 && ((rv_instruction_i[21:20]!=2'b11 && !rv_instruction_i[22])||rv_instruction_i[22:20]==3'b100) && rv_instruction_i[14:2]==13'b0100000000011;
    wire isCBO_CLEAN = (rv_instruction_i[21:20]==2'b01)&(cbcfe|current_privlidge);
    wire isCBO_FLUSH = ((rv_instruction_i[21:20]==2'b10)&(cbcfe|current_privlidge))||((rv_instruction_i[21:20]==2'b00)&(cbie==2'b01 && !current_privlidge));
    wire isCBO_INVAL = (rv_instruction_i[21:20]==2'b00)&(cbie==2'b11||current_privlidge);
    wire isCBO_ZERO = (rv_instruction_i[22:20]==3'b100)&(cbze|current_privlidge);
    wire isFence = rv_instruction_i[19:0]==20'b00000000000000001111;
    wire isCmpBranch = rv_instruction_i[6:2] == 5'b11000;
    wire isCMPBranchInvalid = !rv_instruction_i[14]&rv_instruction_i[13]; // 011 and 11x not used
    wire isJAL = rv_instruction_i[6:2]==5'b11011;
    wire isJALR = (rv_instruction_i[6:2]==5'b11001)&(rv_instruction_i[14:12]==0);
    wire isAUIPC = rv_instruction_i[6:2]==5'b00101;
    wire isLUI = rv_instruction_i[6:2]==5'b01101;
    wire isOP = rv_instruction_i[6:2]==5'b01100;
    wire isOPIMM = rv_instruction_i[6:2]==5'b00100;
    wire isPSX;
     
    wire sys_invalid = !(isECALL|isMRET|isWFI|isCSRRW|isCSRRC|isCSRRS|isEBREAK);
    wire [6:0] uop0; wire port0; wire op_valid0;
    op_dec #(1) opdec0 (rv_instruction_i[31:25], rv_instruction_i[14:12], uop0,port0,op_valid0);
    wire [6:0] uop_imm0; wire op_imm_valid0;
    op_imm_dec opimmdec0 (rv_instruction_i[31:25], rv_instruction_i[14:12], rv_instruction_i[24:20], uop_imm0,op_imm_valid0);
    wire invalid_instruction = !(&rv_instruction_i[1:0])||!(isAUIPC|isLUI|(isOP&op_valid0)|(isOPIMM&op_imm_valid0)|isJAL|isJALR|(isCmpBranch&!isCMPBranchInvalid)|(isLoad&!load_invalid)|(isStore&!store_invalid)
    |(isSystem&!sys_invalid)|isFence|isFenceI|isPSX|(isCMO&(isCBO_CLEAN|isCBO_FLUSH|isCBO_INVAL|isCBO_ZERO)));
    // second instruction
    wire isLoad2 = rv_instruction_i2[6:2]==5'b00000; 
    wire isStore2 = rv_instruction_i2[6:2]==5'b01000;
    wire load_invalid2 = &rv_instruction_i2[14:13]; //11x is invalid given it is load;
    wire store_invalid2 = rv_instruction_i2[14:12] > 3'b010;
    wire isSystem2 = rv_instruction_i2[6:2] == 5'b11100;
    wire isECALL2 = rv_instruction_i2[31:7] == 0;
    wire isEBREAK2 = rv_instruction_i2[31:7] == 25'b000000000001000000000000;
    wire isMRET2 = rv_instruction_i2[31:7]==25'b0011000000100000000000000;
    wire isWFI2 =  rv_instruction_i2[31:7]==25'b0001000001010000000000000;
    wire isCSRRW2 = rv_instruction_i2[13:12]==2'b01;
    wire isCSRRS2 = rv_instruction_i2[13:12]==2'b10;
    wire isCSRRC2 = rv_instruction_i2[13:12]==2'b11;
    wire csr_imm2 = rv_instruction_i2[14];
    wire isFenceI2 = rv_instruction_i2[31:0]==32'b00000000000000000001000000001111;
    wire isCMO2 = rv_instruction_i2[31:23]==9'd0 && ((rv_instruction_i2[21:20]!=2'b11 && !rv_instruction_i2[22])||rv_instruction_i2[22:20]==3'b100) && rv_instruction_i2[14:2]==13'b0100000000011;
    wire isCBO_CLEAN2 = (rv_instruction_i2[22:20]==3'b001)&(cbcfe|current_privlidge);
    wire isCBO_FLUSH2 = ((rv_instruction_i2[22:20]==3'b010)&(cbcfe|current_privlidge))||((rv_instruction_i2[22:20]==3'b000)&(cbie==2'b01 && !current_privlidge));
    wire isCBO_INVAL2 = (rv_instruction_i2[22:20]==3'b000)&(cbie==2'b11||current_privlidge);
    wire isCBO_ZERO2 = (rv_instruction_i2[22:20]==3'b100)&(cbze||current_privlidge);
    wire isFence2 = rv_instruction_i2[19:0]==20'b00000000000000001111;
    wire isCmpBranch2 = rv_instruction_i2[6:2] == 5'b11000;
    wire isCMPBranchInvalid2 = !rv_instruction_i2[14]&rv_instruction_i2[13]; // 011 and 11x not used
    wire isJAL2 = rv_instruction_i2[6:2]==5'b11011;
    wire isJALR2 = rv_instruction_i2[6:2]==5'b11001&(rv_instruction_i2[14:12]==0);
    wire isAUIPC2 = rv_instruction_i2[6:2]==5'b00101;
    wire isLUI2 = rv_instruction_i2[6:2]==5'b01101;
    wire isOP2 = rv_instruction_i2[6:2]==5'b01100;
    wire isOPIMM2 = rv_instruction_i2[6:2]==5'b00100;
    wire isPSX2;
    wire sys_invalid2 = !(isECALL2|isMRET2|isWFI2|isCSRRW2|isCSRRC2|isCSRRS2|isEBREAK2);
    wire [6:0] uop1; wire port1; wire op_valid1;
    op_dec #(1) opdec1 (rv_instruction_i2[31:25], rv_instruction_i2[14:12], uop1,port1,op_valid1);
    wire [6:0] uop_imm1; wire op_imm_valid1;
    op_imm_dec opimmdec1 (rv_instruction_i2[31:25], rv_instruction_i2[14:12], rv_instruction_i2[24:20], uop_imm1,op_imm_valid1);
    wire invalid_instruction2 = !(&rv_instruction_i2[1:0])||!(isAUIPC2|isLUI2|(isOP2&op_valid1)|(isOPIMM2&op_imm_valid1)|isJAL2|isJALR2|(isCmpBranch2&!isCMPBranchInvalid2)|(isLoad2&!load_invalid2)|(isStore2&!store_invalid2)
    |(isSystem2&!sys_invalid2)|isFence2|isFenceI2|isPSX2|(isCMO2&(isCBO_CLEAN2|isCBO_FLUSH2|isCBO_INVAL2|isCBO_ZERO2)));
    wire [3:0] ecall = {2'b10, current_privlidge,current_privlidge};
    wire [3:0] ebreak = 4'd3;
    wire [31:0] jalrImmediate2 = {{20{rv_instruction_i2[31]}},rv_instruction_i2[31:20]};
    wire [31:0] cmpBranchImmediate2 = {{20{rv_instruction_i2[31]}}, rv_instruction_i2[7], rv_instruction_i2[30:25], rv_instruction_i2[11:8], 1'b0};
    wire [31:0] jalImmediate2 = {{11{rv_instruction_i2[31]}}, rv_instruction_i2[31], rv_instruction_i2[19:12], rv_instruction_i2[20], rv_instruction_i2[30:21], 1'b0};
    wire [31:0] auipcImmediate2 = {rv_instruction_i2[31:12], 12'h000};
    wire [31:0] storeImmediate2 = {{20{rv_instruction_i2[31]}}, rv_instruction_i2[31:25], rv_instruction_i2[11:7]};
    initial valid_o = 0;
    //wire ins1_valid = !rv_ppc_i[0]&!(rv_btb_vld&(rv_target!={rv_ppc_i[29:1], 1'd1})&!btb_idx&(rv_btype!=2'b00 ? 1'b1 : rv_bm_pred[1]));
    generate if (ENABLE_PSX) begin : _gen_psx_dec
        assign isPSX = rv_instruction_i[6:2]==5'b01010&(rv_instruction_i[14:12]==0);
        assign isPSX2 = rv_instruction_i2[6:2]==5'b01010&(rv_instruction_i2[14:12]==0);
    end else begin : _gen_psx_ndec
        assign isPSX = 1'b0;
        assign isPSX2 = 1'b0;
    end endgenerate
    wire [1:0] branches_decoded = {(isJAL2|isJALR2|isCmpBranch2)&dec1_instruction_valid, isJAL|isJALR|isCmpBranch};
    wire [IDX_BITS-1:0] first_idx;
    wire [IDX_BITS-1:0] second_idx;
    wire [IDX_BITS-1:0] length_misprediction;
    wire [IDX_BITS-1:0] second_start;
    generate if (ENABLE_C_EXTENSION) begin : _if_IALIGN2
        assign first_idx = dec0_instruction_is_2 ? rv_ppc_i[1:0] : rv_ppc_i[1:0]==2'b00 ? 2'b01 : rv_ppc_i[1:0]==2'b01 ? 2'b10 : rv_ppc_i[1:0]==2'b10 ? 2'b11 : 2'b00;
        assign second_idx = dec1_instruction_is_2 ? first_idx==2'b00 ? 2'b01 : first_idx==2'b01 ? 2'b10 : 2'b11 : first_idx==2'b00 ? 2'b10 : 2'b11;
        assign second_start = dec0_instruction_is_2 ? rv_ppc_i[1:0]==2'b00 ? 2'b01 : rv_ppc_i[1:0]==2'b01 ? 2'b10 : 2'b11 : 2'b10;
        assign length_misprediction[0] = ((rv_ppc_i[1:0]==2'b00 && btb_idx==2'b00) ||
        (rv_ppc_i[1:0]==2'b01 && btb_idx==2'b01) ||
        (rv_ppc_i[1:0]==2'b10 && btb_idx==2'b10))&!dec0_instruction_is_2&&rv_btb_vld;
        assign length_misprediction[1] = ((second_start==2'b00 && btb_idx==2'b00) ||
        (second_start==2'b01 && btb_idx==2'b01) ||
        (second_start==2'b10 && btb_idx==2'b10))&!dec1_instruction_is_2&dec1_instruction_valid&&rv_btb_vld;
    end
    else begin : _if_IALIGN4
        assign first_idx = rv_ppc_i[0];
        assign second_idx = 1'b1;
        assign length_misprediction = 1'd0;
        assign second_start = 1'd0;
    end endgenerate
    wire [1:0] branches_predicted = {rv_btb_vld&dec1_instruction_valid&(btb_idx==second_idx), rv_btb_vld&(btb_idx==first_idx)};
    wire btb_correction = (!branches_decoded[0]&branches_predicted[0])|(!branches_decoded[1]&branches_predicted[1])|(|length_misprediction);
    
    reg [PC_BITS-1:0] address_to_correct;
    always_ff @(posedge cpu_clk_i) begin
        if (flush_i) begin
            shutdown_frontend <= 0;
        end else if (shutdown_frontend) begin
            if (branch_correction_flush) begin
                shutdown_frontend <= 0;
            end
        end else if (rv_valid&btb_correction) begin
            address_to_correct <= rv_ppc_i;
            shutdown_frontend <= 1;
        end
    end
    assign branch_correction_flush = shutdown_frontend&icache_idle&!flush_i&!rn_busy_i;
    assign branch_correction_pc = address_to_correct;
    always_ff @(posedge cpu_clk_i) begin
        if (flush_i|branch_correction_flush) begin
            valid_o <= 0;
        end else if (!rn_busy_i&rv_valid) begin
            ins0_port_o <= !(isJAL|isJALR|isAUIPC|isLUI|(((isOP&!port0)|isOPIMM))|isCmpBranch|isPSX);
            ins0_dnagn_o <= isFenceI|isSystem&(isMRET|isWFI);
            ins0_alu_type_o <= {isPSX,isAUIPC, isLUI, isJALR, isJAL, ((isOP&!port0)|isOPIMM)};
            ins0_alu_opcode_o <= isOP ? uop0 : isOPIMM ? uop_imm0 : isPSX ? {rv_instruction_i[31:25]} : {4'b0000, rv_instruction_i[14:12]};
            ins0_alu_imm_o <= isOPIMM;
            ins0_ios_type_o <= {isCMO, isLoad, isStore, (isCSRRC|isCSRRS|isCSRRW)&isSystem, isFence, (isOP&port0)};
            ins0_ios_opcode_o <= isCMO ? (isCBO_CLEAN ? 3'd0 : isCBO_FLUSH ? 3'd1 : isCBO_INVAL ? 3'd2 : 3'd3) : {rv_instruction_i[14:12]};
            ins0_special_o <= {(isCSRRC|isCSRRS|isCSRRW)&((rv_instruction_i[19:15]!=0)|csr_imm)&isSystem, isMRET&isSystem,isFenceI,isWFI&isSystem};
            ins0_rs1_o <= rv_instruction_i[19:15];
            ins0_rs2_o <= rv_instruction_i[24:20];
            ins0_dest_o <= rv_instruction_i[11:7];
            ins0_imm_o <= isOPIMM|isJALR|isLoad|isSystem ? jalrImmediate : isStore ? storeImmediate : isLUI|isAUIPC ? auipcImmediate : isJAL ? jalImmediate : isCmpBranch ? cmpBranchImmediate : 0; 
            ins0_reg_props_o <= {(isOP|isPSX|isOPIMM|isLoad|isJAL|isJALR|isAUIPC|isLUI|((isCSRRW|isCSRRC|isCSRRS)&isSystem))&&(rv_instruction_i[11:7]!=0), !(((isECALL|isEBREAK|isMRET|isWFI)&isSystem)|isAUIPC|isLUI|isJAL), isOP|isPSX|isCmpBranch|isStore};
            ins0_mov_elim_o <= (rv_instruction_i[31:20]==12'h000)&(rv_instruction_i[14:12]==3'b000)&(rv_instruction_i[6:2]==5'b00100);
            ins1_mov_elim_o <= (rv_instruction_i2[31:20]==12'h000)&(rv_instruction_i2[14:12]==3'b000)&(rv_instruction_i2[6:2]==5'b00100);
            ins0_excp_valid_o <= invalid_instruction|excp_vld|(isSystem&((isMRET&!(current_privlidge))|(isWFI&!current_privlidge&tw)|isECALL|isEBREAK));
            ins1_excp_valid_o <= invalid_instruction2|excp_vld|(isSystem2&((isMRET2&!(current_privlidge))|(isWFI2&!current_privlidge&tw)|isECALL2|isEBREAK2));
            ins0_excp_code_o <= excp_vld ? excp_code : invalid_instruction|(isSystem&(isWFI&!current_privlidge&tw)) ? 4'b0010 : isSystem&isECALL ? ecall : ebreak;
            ins1_excp_code_o <= excp_vld ? excp_code : invalid_instruction|(isSystem2&(isWFI2&!current_privlidge&tw)) ? 4'b0010 : isSystem2&isECALL2 ? ecall : ebreak;
            ins1_port_o <= !(isJAL2|isJALR2|isAUIPC2|isLUI2|(isOP2&!port1)|isOPIMM2|isCmpBranch2|isPSX2);
            ins1_dnagn_o <= isFenceI2|isSystem2&(isMRET2|isWFI2);
            ins1_alu_type_o <= {isPSX2,isAUIPC2, isLUI2, isJALR2, isJAL2, ((isOP2&!port1)|isOPIMM2)};
            ins1_alu_opcode_o <= isOP2 ? uop1 : isOPIMM2 ? uop_imm1 : isPSX2 ? {rv_instruction_i2[31:25]} : {4'b0000, rv_instruction_i2[14:12]};
            ins1_alu_imm_o <= isOPIMM2;
            ins1_ios_type_o <= {isCMO2, isLoad2, isStore2, (isCSRRC2|isCSRRS2|isCSRRW2)&isSystem2, isFence2, (isOP2)&port1};
            ins1_ios_opcode_o <= isCMO2 ? (isCBO_CLEAN2 ? 3'd0 : isCBO_FLUSH2 ? 3'd1 : isCBO_INVAL2 ? 3'd2 : 3'd3) : {rv_instruction_i2[14:12]};
            ins1_special_o <= {(isCSRRC2|isCSRRS2|isCSRRW2)&((rv_instruction_i2[19:15]!=0)|csr_imm2)&isSystem2, isMRET2&isSystem2,isFenceI2, isWFI2&isSystem2};
            ins1_rs1_o <= rv_instruction_i2[19:15];
            ins1_rs2_o <= rv_instruction_i2[24:20];
            ins1_dest_o <= rv_instruction_i2[11:7];
            ins1_imm_o <= isOPIMM2|isJALR2|isLoad2|isSystem2 ? jalrImmediate2 : isStore2 ? storeImmediate2 : isLUI2|isAUIPC2 ? auipcImmediate2 : isJAL2 ? jalImmediate2 : isCmpBranch2 ? cmpBranchImmediate2 : 0; 
            ins1_reg_props_o <= {(isOP2|isPSX2|isOPIMM2|isLoad2|isJAL2|isJALR2|isAUIPC2|isLUI2|((isCSRRW2|isCSRRC2|isCSRRS2)&isSystem2))&&(rv_instruction_i2[11:7]!=0), !(((isECALL2|isEBREAK2|isMRET2|isWFI2)&isSystem2)|isAUIPC2|isLUI2|isJAL2), isPSX2|isOP2|isCmpBranch2|isStore2};
            ins1_valid_o <= dec1_instruction_valid;
            btb_way_o <= btb_way;
            btb_idx_o <= btb_idx;
            btb_btype_o <= rv_btype;
            btb_bm_pred_o <= rv_bm_pred;
            btb_target_o <= rv_target;
            btb_vld_o <= rv_btb_vld;
            insbundle_pc_o <= rv_ppc_i;
            valid_o <= !shutdown_frontend&!btb_correction;
            ins0_dnr_o <= isSystem&(isCSRRC|isCSRRW|isCSRRS)&csr_imm;
            ins1_dnr_o <= isSystem2&(isCSRRC2|isCSRRW2|isCSRRS2)&csr_imm2;
            ins0_hint_o <= {(isJAL|isJALR)&(rv_instruction_i[11:7]==1), isJALR&(jalrImmediate==0)&(rv_instruction_i[19:15]==1)&(rv_instruction_i[11:7]==0)};
            ins1_hint_o <= {(isJAL2|isJALR2)&(rv_instruction_i2[11:7]==1), isJALR2&(jalrImmediate2==0)&(rv_instruction_i2[19:15]==1)&(rv_instruction_i2[11:7]==0)};  
            ins0_2byte_o <= dec0_instruction_is_2;
            ins1_2byte_o <= dec1_instruction_is_2;
        end else if (!rn_busy_i&!rv_valid) begin
            valid_o <= 0;
        end
    end
endmodule
