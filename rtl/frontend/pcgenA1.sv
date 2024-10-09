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

module pcgenA1 #(parameter [31:0] START_ADDR = 32'h0,parameter BPU_ENTRIES = 128,
parameter BPU_ENABLE_RAS = 1, parameter BPU_RAS_ENTRIES = 32)
(
    input   wire logic                      core_clock_i, 
    input   wire logic                      core_reset_i,
    input   wire logic                      core_flush_i,
    input   wire logic [29:0]               core_flush_pc,
    input   wire logic                      enable_branch_pred,
    input   wire logic                      enable_counter_overload,
    input   wire logic                      counter_overload,
    input   wire logic                      tlb_stage_busy_i,

    // decode
    input   wire logic                      btb_correct_i,
    input   wire logic [29:0]               btb_correct_pc,
    // C1 I/O
    input   wire logic [29:0]               c1_btb_vpc_i, //! SIP PC
    input   wire logic [29:0]               c1_btb_target_i, //! SIP Target **if** taken
    input   wire logic [1:0]                c1_cntr_pred_i, //! Bimodal counter prediction,
    input   wire logic                      c1_bnch_tkn_i, //! Branch taken this cycle
    input   wire logic [1:0]                c1_bnch_type_i,
    input   wire logic                      c1_btb_mod_i, // ! BTB modify enable and implies flush
    input   wire logic                      c1_btb_way_i,
    input   wire logic                      c1_btb_bm_i,
    input   wire logic                      c1_call_affirm_i,
    input   wire logic                      c1_ret_affirm_i,

    output       logic                      tlb_stage_valid_o,
    output       logic [29:0]               tlb_stage_pc_o,
    output       logic [1:0]                tlb_btype_o,
    output       logic [1:0]                tlb_bm_pred_o,
    output       logic [29:0]               tlb_btb_target_o,
    output       logic                      tlb_btb_index,
    output       logic                      tlb_btb_hit,
    output       logic                      tlb_btb_way
);
    localparam taglen = $clog2(BPU_ENTRIES/2) % 2 == 1 ? (29-$clog2(BPU_ENTRIES/2))/2  : (29-$clog2(BPU_ENTRIES/2)+1)/2; //! Generate tag lengths appropriate for two way btb search
    //! Program counter
    reg [29:0] program_counter = START_ADDR[31:2];
    wire misaligned = program_counter[0];

    //! Branch prediction store
    reg [29:0] targets [0:BPU_ENTRIES-1];
    reg [1:0]  counters [0:BPU_ENTRIES-1];
    reg [1:0] btype [0:BPU_ENTRIES-1];
    reg idx [0:BPU_ENTRIES-1];
    reg valid0 [0:(BPU_ENTRIES/2)-1]; reg valid1 [0:(BPU_ENTRIES/2)-1];
    reg [taglen-1:0] tag0   [0:(BPU_ENTRIES/2)-1]; reg [taglen-1:0] tag1   [0:(BPU_ENTRIES/2)-1];

    reg [29:0] RAS [0:BPU_RAS_ENTRIES-1];

    reg [$clog2(BPU_RAS_ENTRIES)-1:0] RAS_idx_spec = 0;
    reg [$clog2(BPU_RAS_ENTRIES)-1:0] RAS_idx_real = 0;
    initial begin
        tlb_stage_valid_o = 0;
        tlb_stage_pc_o = 0;
        for (integer i = 0; i < BPU_ENTRIES; i++) begin : _initialise
            targets[i] = 0; counters[i] = 0; btype[i] = 0; idx[i] = 0;
        end
        for (integer i = 0; i < BPU_ENTRIES/2; i++) begin : _initialise
            valid0[i] = 0; valid1[i] = 0; 
            tag0[i] = 0; tag1[i] = 0;
        end
        for (integer i = 0; i < BPU_RAS_ENTRIES; i++) begin : _initialise
            RAS[i] = 0;
        end
    end
    wire [29:0] pc_used = c1_btb_mod_i ? c1_btb_vpc_i : btb_correct_i ? btb_correct_pc : program_counter;
    wire [taglen-1:0] tag_based_on_pc;
    generate
        if ($clog2(BPU_ENTRIES/2) % 2 == 1) begin : ______
            assign tag_based_on_pc = {pc_used[29:30-taglen]^{pc_used[29-taglen:$clog2(BPU_ENTRIES/2)+1]}};
        end else begin : ______________
            assign tag_based_on_pc = {pc_used[29:30-taglen]^{pc_used[29-taglen:$clog2(BPU_ENTRIES/2)+1],1'b0}};
        end
    endgenerate
    
    /**
        RAS works as follows:
        if no misprediction raised:
            - Upon call add to RAS stack and increment
            - Upon ret remove from RAS stack and decrement
        else if misprediction raised:
            - Call: Add to RAS stack and increment real counter and set the spec counter to real +1
            - Ret: Decrement real counter and set the spec counter to real - 1
        Predictions must also be affirmed
        Branch correction flushes act the same as a misprediction to the RAS
    **/
    wire [$clog2(BPU_ENTRIES/2)-1:0] btb_lkp_idx = pc_used[$clog2(BPU_ENTRIES/2):1];
    wire [1:0] tag_match = {
        tag_based_on_pc==tag1[btb_lkp_idx],
        tag_based_on_pc==tag0[btb_lkp_idx]
    };
    wire [1:0] valid_array = {valid1[btb_lkp_idx], valid0[btb_lkp_idx]};
    wire [1:0] match = tag_match&valid_array;

    wire [1:0] btb_bm_pred = enable_counter_overload ? {counter_overload, counter_overload} : counters[{match[1], btb_lkp_idx}];
    wire [1:0] btb_type = btype[{match[1], btb_lkp_idx}];
    wire [29:0] btb_target_bm = targets[{match[1], btb_lkp_idx}];
    wire btb_index = idx[{match[1], btb_lkp_idx}];
    wire btb_hit = (|match)&!(core_reset_i|core_flush_i)&!(!btb_index&program_counter[0]);
    wire [29:0] btb_target;
    generate if (BPU_ENABLE_RAS) begin : _
        assign btb_target = btb_type==2'b11 ? RAS[RAS_idx_spec] : btb_target_bm;    
    end else begin : __
        assign btb_target = btb_target_bm;
    end 
    endgenerate
    wire btb_redirect = btb_hit&(btb_type==2'b00 ? btb_bm_pred[1] : 1'b1);
    wire [29:0] next_pc = btb_redirect&&enable_branch_pred ? btb_target : misaligned ? program_counter + 1 : program_counter + 2;

    always_ff @(posedge core_clock_i) begin
        if (core_reset_i) begin
            tlb_stage_valid_o <= 0;
            program_counter <= START_ADDR[31:2];
        end else if (core_flush_i) begin
            tlb_stage_valid_o <= 0;
            program_counter <= core_flush_pc;
        end else if (!tlb_stage_busy_i) begin
            program_counter <= next_pc;
            tlb_stage_valid_o <= 1;
            tlb_stage_pc_o <= program_counter;
            tlb_btype_o <= btb_type;
            tlb_bm_pred_o <= btb_bm_pred;
            tlb_btb_target_o <= btb_target;
            tlb_btb_index <= btb_index;
            tlb_btb_hit <= btb_hit&&enable_branch_pred;
            tlb_btb_way <= match[1];
        end
    end
    wire call_predicted;
    wire ret_predicted;
    wire call_mispredicted;
    wire ret_mispredicted;
    wire call_affirmed;
    wire ret_affirmed;
    wire [$clog2(BPU_RAS_ENTRIES)-1:0] RAS_idx_spec_p1_w;
    wire [$clog2(BPU_RAS_ENTRIES)-1:0] RAS_idx_real_p1_w;
    wire [$clog2(BPU_RAS_ENTRIES)-1:0] RAS_idx_spec_m1_w;
    wire [$clog2(BPU_RAS_ENTRIES)-1:0] RAS_idx_real_m1_w;
    generate if (BPU_ENABLE_RAS) begin : ___
        assign call_predicted = btb_hit&!tlb_stage_busy_i&(btb_type==2'b01);
        assign ret_predicted = btb_hit&!tlb_stage_busy_i&(btb_type==2'b11);
        assign call_mispredicted = c1_btb_mod_i&(c1_bnch_type_i==2'b01);
        assign ret_mispredicted = c1_btb_mod_i&(c1_bnch_type_i==2'b11);
        assign call_affirmed = c1_call_affirm_i;
        assign ret_affirmed = c1_ret_affirm_i;
        assign RAS_idx_spec_p1_w = RAS_idx_spec + 1;
        assign RAS_idx_real_p1_w = RAS_idx_real + 1;
        assign RAS_idx_spec_m1_w = RAS_idx_spec - 1;
        assign RAS_idx_real_m1_w = RAS_idx_real - 1;
    end else begin : ____
        assign call_predicted = 1'b0;
        assign ret_predicted = 1'b0;
        assign call_mispredicted = 1'b0;
        assign ret_mispredicted = 1'b0;
        assign call_affirmed = 0;
        assign ret_affirmed = 0;
        assign RAS_idx_spec_p1_w = 0;
        assign RAS_idx_real_p1_w = 0;
        assign RAS_idx_spec_m1_w = 0;
        assign RAS_idx_real_m1_w = 0;
    end
    endgenerate
    always_ff @(posedge core_clock_i) begin
        if (core_reset_i) begin
            RAS_idx_spec <= 0;
        end else if (call_mispredicted) begin
            RAS_idx_spec <= RAS_idx_real_p1_w;
            RAS[RAS_idx_real_p1_w] <= c1_btb_vpc_i+1;
        end else if (ret_mispredicted) begin
            RAS_idx_spec <= RAS_idx_real_m1_w;
        end
        else if (call_predicted) begin
            RAS_idx_spec <= RAS_idx_spec_p1_w;
            RAS[RAS_idx_spec_p1_w] <= {program_counter[29:1],btb_index} + 1;
        end else if (ret_predicted) begin
            RAS_idx_spec <= RAS_idx_spec_m1_w;
        end
        if (core_reset_i) begin
            RAS_idx_real <= 0;
        end else if (call_mispredicted|call_affirmed) begin
            RAS_idx_real <= RAS_idx_real_p1_w;
        end else if (ret_mispredicted|ret_affirmed) begin
            RAS_idx_real <= RAS_idx_real_m1_w;
        end
    end
    reg rr = 0;
    wire replacement_idx = &valid_array ? rr : ~valid_array[1];
    wire [1:0] val_to_be_written;
    assign val_to_be_written = c1_bnch_tkn_i ? (c1_cntr_pred_i == 2'b11 ? 2'b11 : c1_cntr_pred_i + 1'b1) : (c1_cntr_pred_i == 2'b00 ? 2'b00 : c1_cntr_pred_i - 1'b1);
 
    always_ff @(posedge core_clock_i) begin
        rr <= ~rr;
        if (c1_btb_mod_i) begin
            if (|match) begin : modify_entry
                counters[{~match[0],btb_lkp_idx}] <= val_to_be_written; btype[{~match[0],btb_lkp_idx}] <= c1_bnch_type_i; targets[{~match[0],btb_lkp_idx}] <= c1_btb_target_i; // here tags are not changed
                valid0[btb_lkp_idx] <= match[0] ?  1 : valid0[btb_lkp_idx];valid1[btb_lkp_idx] <= match[1] ?  1 : valid1[btb_lkp_idx];
                idx[{~match[0], btb_lkp_idx}] <= c1_btb_vpc_i[0];
            end else begin : add_new_entry
                counters[{replacement_idx,btb_lkp_idx}] <=  val_to_be_written; btype[{replacement_idx,btb_lkp_idx}] <= c1_bnch_type_i; targets[{replacement_idx,btb_lkp_idx}] <= c1_btb_target_i;
                valid0[{btb_lkp_idx}] <= replacement_idx==0 ? 1 : valid0[btb_lkp_idx]; valid1[{btb_lkp_idx}] <= replacement_idx==1 ? 1 : valid1[btb_lkp_idx];
                tag0[{btb_lkp_idx}] <= replacement_idx==0 ? tag_based_on_pc : tag0[btb_lkp_idx];tag1[{btb_lkp_idx}] <= replacement_idx==1 ? tag_based_on_pc : tag1[btb_lkp_idx];
                idx[{replacement_idx, btb_lkp_idx}] <= c1_btb_vpc_i[0];
            end
        end else if (btb_correct_i) begin
            valid0[btb_lkp_idx] <= match[0] ?  0 : valid0[btb_lkp_idx];valid1[btb_lkp_idx] <= match[1] ? 0: valid1[btb_lkp_idx];
            idx[{~match[0], btb_lkp_idx}] <= 0;
        end
        if (c1_btb_bm_i&!core_reset_i) begin
            counters[{c1_btb_way_i,c1_btb_vpc_i[$clog2(BPU_ENTRIES/2):1]}] <= val_to_be_written;
        end
    end
    initial tlb_stage_valid_o = 0;
endmodule
