module align (
    input   wire logic                  cpu_clk_i,
    input   wire logic                  flush_i,
    input   wire logic                  icache_valid_i,
    input   wire logic [63:0]           instruction_i,
    input   wire logic [30:0]           if2_sip_vpc_i,
    input   wire logic [3:0]            if2_sip_excp_code_i,
    input   wire logic                  if2_sip_excp_vld_i,
    input   wire logic [1:0]            if2_btb_idx,
    input   wire logic [1:0]            btb_btype_i, //! Branch type: 00 = Cond, 01 = Indirect, 10 - Jump, 11 - Ret
    input   wire logic [1:0]            btb_bm_pred_i, //! Bimodal counter prediction
    input   wire logic [30:0]           btb_target_i, //! Predicted target if branch is taken
    input   wire logic                  btb_vld_i,
    input   wire logic                  btb_way_i,
    output  wire logic                  busy_o,
    // decode
    output       logic                  dec_vld_o,
    output       logic [31:0]           dec0_instruction_o,
    output       logic                  dec0_instruction_is_2,
    output       logic                  dec0_instruction_valid_o,
    output       logic [31:0]           dec1_instruction_o,
    output       logic                  dec1_instruction_is_2,
    output       logic                  dec1_instruction_valid_o,
    output       logic [30:0]           dec_vpc_o,
    output       logic [3:0]            dec_excp_code_o,
    output       logic                  dec_excp_vld_o,
    output       logic [1:0]            dec_btb_index_o,
    output       logic [1:0]            dec_btb_btype_o, //! Branch type: 00 = Cond, 01 = Indirect, 10 - Jump, 11 - Ret
    output       logic [1:0]            dec_btb_bm_pred_o, //! Bimodal counter prediction
    output       logic [30:0]           dec_btb_target_o, //! Predicted target if branch is taken
    output       logic                  dec_btb_vld_o,
    output       logic                  dec_btb_way_o,
    output       logic                  dec_invalidate_o,
    input   wire logic                  dec_busy_i
);
    wire [63:0] working_ins;
    wire [30:0] rv_ppc_i;
    wire [30:0] rv_target; wire [1:0] rv_btype; wire [1:0] rv_bm_pred; wire rv_btb_vld; wire excp_vld; wire [3:0] excp_code;
    wire rv_valid; wire [1:0] btb_idx; wire btb_way;
    skdbf #(.DW(139)) skidbuffer (
        cpu_clk_i, flush_i, dec_busy_i, {working_ins, rv_ppc_i, rv_target, rv_btype, rv_bm_pred, rv_btb_vld, excp_vld, excp_code,btb_idx,btb_way}, rv_valid, busy_o, {instruction_i, if2_sip_vpc_i, btb_target_i, btb_btype_i,
        btb_bm_pred_i, btb_vld_i, if2_sip_excp_vld_i, if2_sip_excp_code_i, if2_btb_idx,btb_way_i}, icache_valid_i
    );
    reg [3:0] alignStageMask = 4'hF; // Mask for partial decoding
    localparam alignIDLE = 2'b00;
    localparam alignREM = 2'b01;
    localparam alignSPECIAL = 2'b10;
    reg [1:0] alignFSM = alignIDLE;

    wire [2:0] pc_start_hw = {
        rv_ppc_i[1:0]==2'b10,
        rv_ppc_i[1:0]==2'b01,
        rv_ppc_i[1:0]==2'b00
    };
    wire [3:0] determine_valid_hw_pc = {
        1'b1, |pc_start_hw, |pc_start_hw[1:0], pc_start_hw[0]
    };
    wire [2:0] idx_end_hw = {
        btb_idx[1:0]==2'b10,
        btb_idx[1:0]==2'b01,
        btb_idx[1:0]==2'b00
    };
    wire [3:0] determine_valid_hw_btb = {
        !(|idx_end_hw), !(|idx_end_hw[1:0]), !(idx_end_hw[0]), 1'b1
    };

    wire [3:0] hw_accept = determine_valid_hw_pc&determine_valid_hw_btb&alignStageMask;


    logic [31:0] first_instruction;
    logic [3:0] hw_mask_off;
    wire first_32 = first_instruction[1:0]==2'b11;
    always_comb begin
        casez (hw_accept)
            4'bzzz1: begin
                first_instruction = working_ins[31:0];
            end
            4'bzz10: begin
                first_instruction = working_ins[47:16];
            end
            4'bz100: begin
                first_instruction = working_ins[63:32];
            end
            4'b1000: begin
                first_instruction = {16'hx, working_ins[63:48]};
            end
            default: begin
                first_instruction = {30'hx, 2'b00}; // pretend that its 16-bit
            end
        endcase
        casez (hw_accept)
            4'bzzz1: begin
                hw_mask_off = first_32 ? 4'b0011 : 4'b0001;
            end
            4'bzz10: begin
                hw_mask_off = first_32 ? 4'b0110 : 4'b0010;
            end
            4'bz100: begin
                hw_mask_off = first_32 ? 4'b1100 : 4'b0100;
            end
            4'b1000: begin
                hw_mask_off = first_32 ? 4'b0000 : 4'b1000;
            end
            default: begin
                hw_mask_off = '0;
            end
        endcase
    end

    wire [3:0]  hw_accept_2 = hw_accept&~hw_mask_off;
    logic [31:0] second_instruction;
    logic [3:0] hw_mask_off_2;
    wire second_32 = second_instruction[1:0]==2'b11;
    always_comb begin
        casez (hw_accept_2)
            4'bzzz1: begin
                second_instruction = working_ins[31:0];
            end
            4'bzz10: begin
                second_instruction = working_ins[47:16];
            end
            4'bz100: begin
                second_instruction = working_ins[63:32];
            end
            4'b1000: begin
                second_instruction = {16'hx, working_ins[63:48]};
            end
            default: begin
                second_instruction = {30'hx, 2'b00}; // pretend that its 16-bit
            end
        endcase
        casez (hw_accept_2)
            4'bzzz1: begin
                hw_mask_off_2 = second_32 ? 4'b0011 : 4'b0001;
            end
            4'bzz10: begin
                hw_mask_off_2 = second_32 ? 4'b0110 : 4'b0010;
            end
            4'bz100: begin
                hw_mask_off_2 = second_32 ? 4'b1100 : 4'b0100;
            end
            4'b1000: begin
                hw_mask_off_2 = second_32 ? 4'b0000 : 4'b1000;
            end
            default: begin
                hw_mask_off_2 = '0;
            end
        endcase
    end
    wire [31:0] decompressed_32_0; wire illegal_0;
    wire [31:0] decompressed_32_1; wire illegal_1;

    decompressor d0 (first_instruction[15:0], decompressed_32_0, illegal_0);
    decompressor d1 (second_instruction[15:0], decompressed_32_1, illegal_1);

    // Prediction sanity check, in this case ignore bytes consumed
    wire invalidate_btb_entry = (first_32&((hw_mask_off&hw_accept)!=hw_mask_off))||(second_32&((hw_mask_off_2&hw_accept_2)!=hw_mask_off_2));
    
    // Check for fetch resp misaligned instruction
    wire first_incomplete_32 = (first_32&&(hw_accept==4'b1000));
    wire second_incomplete_32 = (second_32&&(hw_accept_2==4'b1000));

    // Check for amount of bytes consumed
    wire all_bytes_consumed = hw_accept==(hw_mask_off|hw_mask_off_2);

    wire [1:0] first_accepted = hw_mask_off[3] ? 2'b11 : hw_mask_off[2] ? 2'b10 : hw_mask_off[1] ? 2'b01 : 2'b00;
    wire [1:0] second_accepted = hw_mask_off_2[3] ? 2'b11 : hw_mask_off_2[2] ? 2'b10 : hw_mask_off_2[1] ? 2'b01 : 2'b00;
    always_ff @(posedge cpu_clk_i) begin
        if (flush_i) begin
            alignFSM <= alignIDLE;
        end else if (!dec_busy_i) begin
            case (alignFSM)
                2'b00: begin
                    if (rv_valid) begin
                        if (first_32) begin
                            dec0_instruction_o <= first_instruction;
                            dec0_instruction_is_2 <= 1'b0;
                            dec0_instruction_valid_o <= !first_incomplete_32;
                        end else begin
                            dec0_instruction_o <= decompressed_32_0;
                            dec0_instruction_is_2 <= 1'b1;
                            dec0_instruction_valid_o <= 1'b1;
                        end
                        if (second_32) begin
                            dec1_instruction_o <= first_instruction;
                            dec1_instruction_is_2 <= 1'b0;
                            dec1_instruction_valid_o <= !second_incomplete_32 && (hw_accept_2!='0);
                        end else begin
                            dec1_instruction_o <= decompressed_32_0;
                            dec1_instruction_is_2 <= 1'b1;
                            dec1_instruction_valid_o <= (hw_accept_2!='0);
                        end
                        dec_invalidate_o <= invalidate_btb_entry;
                        dec_vld_o <= 1'b1;
                        dec_vpc_o <= {rv_ppc_i[30:2], first_accepted};
                        dec_btb_bm_pred_o <= rv_bm_pred;
                        dec_btb_btype_o <= rv_btype;
                        dec_btb_index_o <= btb_idx;
                        dec_btb_way_o <= btb_way;
                        dec_btb_target_o <= rv_target;
                        dec_btb_vld_o <= rv_btb_vld&((first_accepted==btb_idx)||(second_accepted==btb_idx));
                        if (!all_bytes_consumed) begin
                            alignStageMask <= ~(hw_mask_off|hw_mask_off_2);
                            if (first_incomplete_32|second_incomplete_32) begin
                                alignFSM <= alignSPECIAL;
                            end
                        end else begin
                            alignStageMask <= 4'hF;
                        end
                    end
                end
                alignREM: begin
                    
                end
            endcase
        end
    end

    

endmodule
