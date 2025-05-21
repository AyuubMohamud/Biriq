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
// verilator lint_off DECLFILENAME
module iiie_ifu ();
  iiie_predict iiie_predict ();
  iiie_icache iiie_icache ();
  iiie_decode iiie_decode ();
endmodule
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


module iiie_decode ();

endmodule
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


module iiie_icache #(
    parameter C_XSB1_ID_WIDTH = 3,
    parameter C_ICACHE_SIZE = 8192,
    localparam ID = C_XSB1_ID_WIDTH
) (
    input  wire           core_clock_i,
    input  wire           core_reset_i,
    input  wire  [  29:0] fetch_pc,
    input  wire           fetch_valid,
    output logic          fetch_stall,
    output logic [  63:0] decode_instr,
    input  wire           decode_stall,
    // cache control
    input  wire           cache_flush_i,
    output wire           flush_resp_o,
    // lfsr thingy for cache replacement
    input  wire           lfsr_random_bit,
    // XSB1 Interface
    output logic [ID-1:0] S_XSB_TID,
    output logic [  31:0] S_XSB_ADDR,
    output logic [   1:0] S_XSB_OPCODE,
    output logic [   1:0] S_XSB_LEN,
    output logic          S_XSB_LOCK,
    output logic          S_XSB_EXCL,
    output logic [  63:0] S_XSB_WDATA,
    output logic [   7:0] S_XSB_MASK,
    output logic          S_XSB_WLAST,
    output logic          S_XSB_ENABLE,
    input  wire           S_XSB_READY,
    input  wire  [ID-1:0] S_XSB_RID,
    input  wire  [  63:0] S_XSB_RDATA,
    input  wire  [   1:0] S_XSB_RESP,
    input  wire           S_XSB_RLAST,
    input  wire           S_XSB_VALID,
    output logic          S_XSB_IDLEn
);

  localparam SETS = C_ICACHE_SIZE / 64;
  localparam SETS_PER_WAY = SETS / 2;
  localparam TAGL = 26 - $clog2(SETS_PER_WAY);

  reg [TAGL-1:0] tag0[0:SETS_PER_WAY-1];
  reg [TAGL-1:0] tag1[0:SETS_PER_WAY-1];
  reg valid0[0:SETS_PER_WAY-1];
  reg valid1[0:SETS_PER_WAY-1];
  reg [$clog2(SETS_PER_WAY)-1:0] counter_q;
  reg [2:0] word_q;
  reg [63:0] icache_ram[0:(C_ICACHE_SIZE/8)-1];
  typedef enum logic [1:0] {
    IDLE,
    FILL,
    FLUSH,
    BLOCK
  } icache_state_t;
  icache_state_t icache_state;
  icache_state_t next_state;
  wire [TAGL-1:0] tag_read_0;
  wire [TAGL-1:0] tag_read_1;
  wire valid_read_0;
  wire valid_read_1;
  wire tag_match_0;
  wire tag_match_1;
  wire miss;
  wire [$clog2(SETS_PER_WAY)-1:0] counter_p1;
  wire [2:0] word_p1;
  wire set_replacement;

  initial begin
    for (integer i = 0; i < SETS_PER_WAY; i++) begin
      tag0[i]   = '0;
      tag1[i]   = '0;
      valid0[i] = '0;
      valid1[i] = '0;
    end
    counter_q = '0;
    word_q    = '0;
    icache_state = IDLE;
  end

  always_comb
    case (icache_state)
      IDLE: fetch_stall = miss;
      FILL: fetch_stall = 1'b1;
      FLUSH: fetch_stall = 1'b1;
      BLOCK: fetch_stall = 1'b1;
      default: fetch_stall = 1'bx;
    endcase

  always_comb
    case (icache_state)
      IDLE: next_state = cache_flush_i ? FLUSH : miss ? FILL : IDLE;
      FILL: next_state = S_XSB_RLAST && S_XSB_VALID ? IDLE : FILL;
      FLUSH: next_state = &counter_q ? BLOCK : FLUSH;
      BLOCK: next_state = BLOCK;
      default: next_state = IDLE;
    endcase

  always_ff @(posedge core_clock_i)
    if (core_reset_i) begin
      S_XSB_ENABLE <= 1'b0;
    end else
      case (icache_state)
        IDLE: S_XSB_ENABLE <= next_state == FILL;
        FILL: S_XSB_ENABLE <= S_XSB_ENABLE & !S_XSB_READY;
        default: S_XSB_ENABLE <= 1'b0;
      endcase

  always_ff @(posedge core_clock_i)
    case (icache_state)
      IDLE: if (next_state == FILL) S_XSB_ADDR <= {fetch_pc[29:4], 6'd0};
      default: S_XSB_ADDR <= S_XSB_ADDR;
    endcase

  always_ff @(posedge core_clock_i)
    if (!decode_stall)
      decode_instr <= icache_ram[{tag_match_1, fetch_pc[3+$clog2(SETS_PER_WAY):1]}];

  always_ff @(posedge core_clock_i)
    if (core_reset_i) counter_q <= '0;
    else
      case (icache_state)
        FILL: if (S_XSB_VALID) counter_q <= counter_p1;
        FLUSH: counter_q <= counter_p1;
        default: counter_q <= '0;
      endcase

  always_ff @(posedge core_clock_i)
    if (core_reset_i) word_q <= '0;
    else
      case (icache_state)
        FILL: if (S_XSB_VALID) word_q <= word_p1;
        default: word_q <= '0;
      endcase

  always_ff @(posedge core_clock_i)
    if ((icache_state == FILL) && S_XSB_VALID)
      icache_ram[{set_replacement, fetch_pc[3+$clog2(SETS_PER_WAY):4], word_q}] <= S_XSB_RDATA;

  always_ff @(posedge core_clock_i)
    if ((icache_state == FILL) && (word_q == 3'd7) && S_XSB_VALID && set_replacement)
      tag1[S_XSB_ADDR[5+$clog2(SETS_PER_WAY):6]] <= S_XSB_ADDR[31:6+$clog2(SETS_PER_WAY)];

  always_ff @(posedge core_clock_i)
    if ((icache_state == FILL) && (word_q == 3'd7) && S_XSB_VALID && !set_replacement)
      tag0[S_XSB_ADDR[5+$clog2(SETS_PER_WAY):6]] <= S_XSB_ADDR[31:6+$clog2(SETS_PER_WAY)];

  always_ff @(posedge core_clock_i)
    if ((icache_state == FILL) && (word_q == 3'd7) && S_XSB_VALID && set_replacement)
      valid1[S_XSB_ADDR[5+$clog2(SETS_PER_WAY):6]] <= 1'b1;
    else if (icache_state == FLUSH) valid1[counter_q] <= 1'b0;

  always_ff @(posedge core_clock_i)
    if ((icache_state == FILL) && (word_q == 3'd7) && S_XSB_VALID && !set_replacement)
      valid0[S_XSB_ADDR[5+$clog2(SETS_PER_WAY):6]] <= 1'b1;
    else if (icache_state == FLUSH) valid0[counter_q] <= 1'b0;

  always_ff @(posedge core_clock_i) icache_state <= next_state;

  assign counter_p1      = counter_q + 1;
  assign word_p1         = word_q + 1;
  assign tag_read_0      = tag0[fetch_pc[3+$clog2(SETS_PER_WAY):4]];
  assign tag_read_1      = tag1[fetch_pc[3+$clog2(SETS_PER_WAY):4]];
  assign valid_read_0    = valid0[fetch_pc[3+$clog2(SETS_PER_WAY):4]];
  assign valid_read_1    = valid1[fetch_pc[3+$clog2(SETS_PER_WAY):4]];
  assign tag_match_0     = (tag_read_0 == fetch_pc[29:4+$clog2(SETS_PER_WAY)]) & valid_read_0;
  assign tag_match_1     = (tag_read_1 == fetch_pc[29:4+$clog2(SETS_PER_WAY)]) & valid_read_1;
  assign miss            = fetch_valid && !(tag_match_0 || tag_match_1) && !decode_stall;
  assign set_replacement = valid_read_0 & valid_read_1 ? lfsr_random_bit : valid_read_0;
  assign S_XSB_TID       = '0;
  assign S_XSB_EXCL      = '0;
  assign S_XSB_LOCK      = '0;
  assign S_XSB_WLAST     = '1;
  assign S_XSB_MASK      = '0;
  assign S_XSB_WDATA     = '0;
  assign S_XSB_OPCODE    = '0;
  assign S_XSB_IDLEn     = 1'b1;
  assign S_XSB_LEN       = 2'd2;
  assign flush_resp_o    = icache_state == IDLE;

  // verilator lint_off UNUSED
  wire unused;
  assign unused = (|S_XSB_RID) | fetch_pc[0] | (|S_XSB_RESP);
  // verilator lint_on UNUSED
endmodule
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module iiie_predict #(
    parameter [31:0] C_RESET_ADDR = 32'h0,
    parameter C_BTB_ENTRIES = 64
) (
    input  wire         core_clock_i,
    input  wire         core_reset_i,
    input  wire         core_flush_i,
    input  wire  [29:0] core_flush_pc,
    input  wire         enable_branch_pred,
    input  wire         enable_counter_overload,
    input  wire         counter_overload,
    input  wire         ic_busy_i,
    // decode
    input  wire         btb_correct_i,
    input  wire  [29:0] btb_correct_pc,
    // Commit
    input  wire  [29:0] cm_btb_vpc_i,             //! SIP PC
    input  wire  [29:0] cm_btb_target_i,          //! SIP Target **if** taken
    input  wire  [ 1:0] cm_cntr_pred_i,           //! Bimodal counter prediction,
    input  wire         cm_bnch_tkn_i,            //! Branch taken this cycle
    input  wire  [ 1:0] cm_bnch_type_i,
    input  wire         cm_btb_mod_i,             // ! BTB modify enable and implies flush
    input  wire         cm_btb_way_i,
    input  wire         cm_btb_bm_i,
    output logic        ic_valid,
    output logic [29:0] ic_pc,
    output logic [ 1:0] ic_btype,
    output logic [ 1:0] ic_bm_pred,
    output logic [29:0] ic_btb_target,
    output logic        ic_btb_index,
    output logic        ic_btb_hit,
    output logic        ic_btb_way
);
  localparam taglen = $clog2(
      C_BTB_ENTRIES / 2
  ) % 2 == 1 ? (29 - $clog2(
      C_BTB_ENTRIES / 2
  )) / 2 : (29 - $clog2(
      C_BTB_ENTRIES / 2
  ) + 1) / 2;  //! Generate tag lengths appropriate for two way btb search
  //! Program counter
  reg [29:0] program_counter;
  initial program_counter = C_RESET_ADDR[31:2];
  wire misaligned;
  assign misaligned = program_counter[0];

  //! Branch prediction store
  reg [29:0] targets [0:C_BTB_ENTRIES-1];
  reg [1:0]  counters [0:C_BTB_ENTRIES-1];
  reg [1:0] btype [0:C_BTB_ENTRIES-1];
  reg idx [0:C_BTB_ENTRIES-1];
  reg valid0 [0:(C_BTB_ENTRIES/2)-1];
  reg valid1 [0:(C_BTB_ENTRIES/2)-1];
  reg [taglen-1:0] tag0   [0:(C_BTB_ENTRIES/2)-1];
  reg [taglen-1:0] tag1   [0:(C_BTB_ENTRIES/2)-1];

  //reg [29:0] RAS [0:BPU_RAS_ENTRIES-1];

  //reg [$clog2(BPU_RAS_ENTRIES)-1:0] RAS_idx_spec = 0;
  //reg [$clog2(BPU_RAS_ENTRIES)-1:0] RAS_idx_real = 0;
  initial begin
    ic_valid = 0;
    ic_pc = 0;
    for (integer i = 0; i < C_BTB_ENTRIES; i++) begin : _initialise
      targets[i] = 0;
      counters[i] = 0;
      btype[i] = 0;
      idx[i] = 0;
    end
    for (integer i = 0; i < C_BTB_ENTRIES / 2; i++) begin : _initialise
      valid0[i] = 0;
      valid1[i] = 0;
      tag0[i]   = 0;
      tag1[i]   = 0;
    end
    //for (integer i = 0; i < BPU_RAS_ENTRIES; i++) begin : _initialise
    //  RAS[i] = 0;
    //end
  end
  wire [29:0] pc_used;
  assign pc_used = cm_btb_mod_i ? cm_btb_vpc_i : btb_correct_i ? btb_correct_pc : program_counter;
  wire [taglen-1:0] tag_based_on_pc;
  generate
    if ($clog2(C_BTB_ENTRIES / 2) % 2 == 1) begin : ______
      assign tag_based_on_pc = {
        pc_used[29:30-taglen] ^ {pc_used[29-taglen:$clog2(C_BTB_ENTRIES/2)+1]}
      };
    end else begin : ______________
      assign tag_based_on_pc = {
        pc_used[29:30-taglen] ^ {pc_used[29-taglen:$clog2(C_BTB_ENTRIES/2)+1], 1'b0}
      };
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
  wire [$clog2(C_BTB_ENTRIES/2)-1:0] btb_lkp_idx;
  assign btb_lkp_idx = pc_used[$clog2(C_BTB_ENTRIES/2):1];
  wire [1:0] tag_match;
  assign tag_match = {tag_based_on_pc == tag1[btb_lkp_idx], tag_based_on_pc == tag0[btb_lkp_idx]};
  wire [1:0] valid_array;
  assign valid_array = {valid1[btb_lkp_idx], valid0[btb_lkp_idx]};
  wire [1:0] match;
  assign match = tag_match & valid_array;

  wire [1:0] btb_bm_pred;
  assign btb_bm_pred = enable_counter_overload ? {counter_overload, counter_overload} : counters[{match[1], btb_lkp_idx}];
  wire [1:0] btb_type;
  assign btb_type = btype[{match[1], btb_lkp_idx}];
  wire [29:0] btb_target_bm;
  assign btb_target_bm = targets[{match[1], btb_lkp_idx}];
  wire btb_index;
  assign btb_index = idx[{match[1], btb_lkp_idx}];
  wire btb_hit;
  assign btb_hit = (|match) & !(core_reset_i | core_flush_i) & !(!btb_index & program_counter[0]);
  wire [29:0] btb_target;

  assign btb_target = btb_target_bm;

  wire btb_redirect;
  assign btb_redirect = btb_hit & (btb_type == 2'b00 ? btb_bm_pred[1] : 1'b1);
  wire [29:0] next_pc;
  wire [29:0] constant;
  assign constant = misaligned ? 30'd1 : 30'd2;
  assign next_pc  = btb_redirect && enable_branch_pred ? btb_target : program_counter + constant;

  //always_ff @(posedge core_clock_i) begin
  //  if (core_reset_i) begin
  //    ic_valid <= 0;
  //    program_counter <= C_RESET_ADDR[31:2];
  //  end else if (core_flush_i) begin
  //    ic_valid <= 0;
  //    program_counter <= core_flush_pc;
  //  end else if (!ic_busy_i) begin
  //    program_counter <= next_pc;
  //    ic_valid <= 1;
  //    ic_pc <= program_counter;
  //    ic_btype <= btb_type;
  //    ic_bm_pred <= btb_bm_pred;
  //    ic_btb_target <= btb_target;
  //    ic_btb_index <= btb_index;
  //    ic_btb_hit <= btb_hit && enable_branch_pred;
  //    ic_btb_way <= match[1];
  //  end
  //end

  always_ff @(posedge core_clock_i) begin
    if (core_reset_i) begin
      program_counter <= C_RESET_ADDR[31:2];
    end else if (core_flush_i) begin
      program_counter <= core_flush_pc;
    end else if (!ic_busy_i) begin
      program_counter <= next_pc;
    end
  end

  assign ic_pc = program_counter;
  assign ic_btype = btb_type;
  assign ic_bm_pred = btb_bm_pred;
  assign ic_btb_target = btb_target;
  assign ic_btb_hit = btb_hit && enable_branch_pred;
  assign ic_btb_way = match[1];
  assign ic_btb_index = btb_index;

  //wire call_predicted;
  //wire ret_predicted;
  //wire call_mispredicted;
  //wire ret_mispredicted;
  //wire call_affirmed;
  //wire ret_affirmed;
  //wire [$clog2(BPU_RAS_ENTRIES)-1:0] RAS_idx_spec_p1_w;
  //wire [$clog2(BPU_RAS_ENTRIES)-1:0] RAS_idx_real_p1_w;
  //wire [$clog2(BPU_RAS_ENTRIES)-1:0] RAS_idx_spec_m1_w;
  //wire [$clog2(BPU_RAS_ENTRIES)-1:0] RAS_idx_real_m1_w;
  //generate
  //  if (BPU_ENABLE_RAS) begin : ___
  //    assign call_predicted = btb_hit & !ic_busy_i & (btb_type == 2'b01);
  //    assign ret_predicted = btb_hit & !ic_busy_i & (btb_type == 2'b11);
  //    assign call_mispredicted = cm_btb_mod_i & (cm_bnch_type_i == 2'b01);
  //    assign ret_mispredicted = cm_btb_mod_i & (cm_bnch_type_i == 2'b11);
  //    assign call_affirmed = cm_call_affirm_i;
  //    assign ret_affirmed = cm_ret_affirm_i;
  //    assign RAS_idx_spec_p1_w = RAS_idx_spec + 1;
  //    assign RAS_idx_real_p1_w = RAS_idx_real + 1;
  //    assign RAS_idx_spec_m1_w = RAS_idx_spec - 1;
  //    assign RAS_idx_real_m1_w = RAS_idx_real - 1;
  //  end else begin : ____
  //    assign call_predicted = 1'b0;
  //    assign ret_predicted = 1'b0;
  //    assign call_mispredicted = 1'b0;
  //    assign ret_mispredicted = 1'b0;
  //    assign call_affirmed = 0;
  //    assign ret_affirmed = 0;
  //    assign RAS_idx_spec_p1_w = 0;
  //    assign RAS_idx_real_p1_w = 0;
  //    assign RAS_idx_spec_m1_w = 0;
  //    assign RAS_idx_real_m1_w = 0;
  //  end
  //endgenerate
  //always_ff @(posedge core_clock_i) begin
  //  if (core_reset_i) begin
  //    RAS_idx_spec <= 0;
  //  end else if (call_mispredicted) begin
  //    RAS_idx_spec <= RAS_idx_real_p1_w;
  //    RAS[RAS_idx_real_p1_w] <= cm_btb_vpc_i + 1;
  //  end else if (ret_mispredicted) begin
  //    RAS_idx_spec <= RAS_idx_real_m1_w;
  //  end else if (call_predicted) begin
  //    RAS_idx_spec <= RAS_idx_spec_p1_w;
  //    RAS[RAS_idx_spec_p1_w] <= {program_counter[29:1], btb_index} + 1;
  //  end else if (ret_predicted) begin
  //    RAS_idx_spec <= RAS_idx_spec_m1_w;
  //  end
  //  if (core_reset_i) begin
  //    RAS_idx_real <= 0;
  //  end else if (call_mispredicted | call_affirmed) begin
  //    RAS_idx_real <= RAS_idx_real_p1_w;
  //  end else if (ret_mispredicted | ret_affirmed) begin
  //    RAS_idx_real <= RAS_idx_real_m1_w;
  //  end
  //end
  reg rr;
  initial rr = 1'b0;
  wire replacement_idx;
  assign replacement_idx = &valid_array ? rr : ~valid_array[1];
  wire [1:0] val_to_be_written;
  assign val_to_be_written = cm_bnch_tkn_i ? (cm_cntr_pred_i == 2'b11 ? 2'b11 : cm_cntr_pred_i + 1'b1) : (cm_cntr_pred_i == 2'b00 ? 2'b00 : cm_cntr_pred_i - 1'b1);

  always_ff @(posedge core_clock_i) begin
    rr <= ~rr;
    if (cm_btb_mod_i) begin
      if (|match) begin : modify_entry
        btype[{~match[0], btb_lkp_idx}] <= cm_bnch_type_i;
        targets[{~match[0], btb_lkp_idx}] <= cm_btb_target_i;  // here tags are not changed
        valid0[btb_lkp_idx] <= match[0] ? 1 : valid0[btb_lkp_idx];
        valid1[btb_lkp_idx] <= match[1] ? 1 : valid1[btb_lkp_idx];
        idx[{~match[0], btb_lkp_idx}] <= cm_btb_vpc_i[0];
      end else begin : add_new_entry
        btype[{replacement_idx, btb_lkp_idx}] <= cm_bnch_type_i;
        targets[{replacement_idx, btb_lkp_idx}] <= cm_btb_target_i;
        valid0[{btb_lkp_idx}] <= replacement_idx == 0 ? 1 : valid0[btb_lkp_idx];
        valid1[{btb_lkp_idx}] <= replacement_idx == 1 ? 1 : valid1[btb_lkp_idx];
        tag0[{btb_lkp_idx}] <= replacement_idx == 0 ? tag_based_on_pc : tag0[btb_lkp_idx];
        tag1[{btb_lkp_idx}] <= replacement_idx == 1 ? tag_based_on_pc : tag1[btb_lkp_idx];
        idx[{replacement_idx, btb_lkp_idx}] <= cm_btb_vpc_i[0];
      end
    end else if (btb_correct_i) begin
      valid0[btb_lkp_idx] <= match[0] ? 0 : valid0[btb_lkp_idx];
      valid1[btb_lkp_idx] <= match[1] ? 0 : valid1[btb_lkp_idx];
      idx[{~match[0], btb_lkp_idx}] <= 0;
    end
    if (cm_btb_mod_i) begin
      if (|match) begin : modify_count_entry
        counters[{~match[0], btb_lkp_idx}] <= val_to_be_written;
      end else begin : add_new_count_entry
        counters[{replacement_idx, btb_lkp_idx}] <= val_to_be_written;
      end
    end else if (cm_btb_bm_i & !core_reset_i) begin
      counters[{cm_btb_way_i, cm_btb_vpc_i[$clog2(C_BTB_ENTRIES/2):1]}] <= val_to_be_written;
    end
  end
  initial ic_valid = 0;
endmodule
