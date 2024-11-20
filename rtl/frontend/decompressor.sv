// ORIGINAL COPYRIGHT NOTICE:
// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE.muntjac for details.
// SPDX-License-Identifier: Apache-2.0

// Relicensed under:
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
// original module name: muntjac_compressed_decoder
// This module decompresses RV32C instructions to full RV32 instructions.
module decompressor (
  input  logic [15:0] instr_i,
  output logic [31:0] instr_o,
  output logic        illegal_instr_o
);

  ////////////////////////////////////////////////////////
  // Helper functions to reconstruct 32-bit instruction //
  ////////////////////////////////////////////////////////

  function logic [31:0] construct_r_type (
    input  [6:0]  funct7,
    input  [4:0]  rs2,
    input  [4:0]  rs1,
    input  [2:0]  funct3,
    input  [4:0]  rd,
    input  [6:0]  opcode
  );
    construct_r_type = {funct7, rs2, rs1, funct3, rd, opcode};
  endfunction

  function logic [31:0] construct_i_type (
    input  [11:0] imm,
    input  [4:0]  rs1,
    input  [2:0]  funct3,
    input  [4:0]  rd,
    input  [6:0]  opcode
  );
    construct_i_type = {imm, rs1, funct3, rd, opcode};
  endfunction

  function logic [31:0] construct_s_type (
    input  [11:0] imm,
    input  [4:0]  rs2,
    input  [4:0]  rs1,
    input  [2:0]  funct3,
    input  [6:0]  opcode
  );
    construct_s_type = {imm[11:5], rs2, rs1, funct3, imm[4:0], opcode};
  endfunction

  function logic [31:0] construct_b_type (
    input  [12:0] imm,
    input  [4:0]  rs2,
    input  [4:0]  rs1,
    input  [2:0]  funct3,
    input  [6:0]  opcode
  );
    construct_b_type = {imm[12], imm[10:5], rs2, rs1, funct3, imm[4:1], imm[11], opcode};
  endfunction

  function logic [31:0] construct_u_type (
    input  [19:0] imm,
    input  [4:0]  rd,
    input  [6:0]  opcode
  );
    construct_u_type = {imm, rd, opcode};
  endfunction

  function logic [31:0] construct_j_type (
    input  [20:0] imm,
    input  [4:0]  rd,
    input  [6:0]  opcode
  );
    construct_j_type = {imm[20], imm[10:1], imm[11], imm[19:12], rd, opcode};
  endfunction

  ////////////////////
  // Field decoding //
  ////////////////////
  localparam [6:0] OPCODE_OP_IMM = 7'b0010011;
  localparam [6:0] OPCODE_OP = 7'b0110011;
  localparam [6:0] OPCODE_LOAD = 7'b0000011;
  localparam [6:0] OPCODE_STORE = 7'b0100011;
  localparam [6:0] OPCODE_LUI = 7'b0110111;
  localparam [6:0] OPCODE_JAL = 7'b1101111;
  localparam [6:0] OPCODE_BRANCH = 7'b1100011;
  localparam [6:0] OPCODE_JALR = 7'b1100111;
  wire [2:0] c_funct3 = instr_i[15:13];
  wire [4:0] c_rd     = instr_i[11:7];
  wire [4:0] c_rs1    = c_rd;
  wire [4:0] c_rs2    = instr_i[6:2];
  wire [4:0] c_rds    = {2'b01, instr_i[4:2]};
  wire [4:0] c_rs1s   = {2'b01, instr_i[9:7]};
  wire [4:0] c_rs2s   = c_rds;

  wire [11:0] ci_imm          = { {7{instr_i[12]}}, instr_i[6:2] };
  wire [11:0] ci_lwsp_imm     = { 4'b0, instr_i[3:2], instr_i[12], instr_i[6:4], 2'b0 };
  wire [11:0] ci_addi16sp_imm = { {3{instr_i[12]}}, instr_i[4:3], instr_i[5], instr_i[2], instr_i[6], 4'b0 };
  wire [11:0] css_swsp_imm    = { 4'b0, instr_i[8:7], instr_i[12:9], 2'b0 };
  wire [11:0] ciw_imm         = { 2'd0, instr_i[10:7], instr_i[12:11], instr_i[5], instr_i[6], 2'b0 };
  wire [11:0] cl_lw_imm       = { 5'b0, instr_i[5], instr_i[12:10], instr_i[6], 2'b0 };
  wire [11:0] cs_sw_imm       = cl_lw_imm;
  wire [12:0] cb_imm          = { {5{instr_i[12]}}, instr_i[6:5], instr_i[2], instr_i[11:10], instr_i[4:3], 1'b0 };
  wire [20:0] cj_imm          = { {10{instr_i[12]}}, instr_i[8], instr_i[10:9], instr_i[6], instr_i[7], instr_i[2], instr_i[11], instr_i[5:3], 1'b0 };

  ////////////////////////
  // Compressed decoder //
  ////////////////////////
  wire [11:0] clb_imm = {{10{1'b0}}, instr_i[5], instr_i[6]};
  wire [11:0] clhu_imm = {{10{1'b0}}, instr_i[5], 1'b0};
  always_comb begin
    // By default decompress to an invalid instruction.
    instr_o = '0;
    illegal_instr_o = 1'b0;

    unique case (instr_i[1:0])
      2'b00: begin
        unique case (c_funct3)
          3'b000: begin
            // c.addi4spn -> addi rd', x2, ciw_imm
            instr_o = construct_i_type (
              .imm (ciw_imm),
              .rs1 (2),
              .funct3 (3'b000),
              .rd (c_rds),
              .opcode (OPCODE_OP_IMM)
            );
            if (ciw_imm == 0) illegal_instr_o = 1'b1;
          end
          3'b001: begin
              illegal_instr_o = 1'b1;
          end
          3'b010: begin
            // c.lw -> lw rd', rs1', cl_lw_imm
            instr_o = construct_i_type (
              .imm (cl_lw_imm),
              .rs1 (c_rs1s),
              .funct3 (3'b010),
              .rd (c_rds),
              .opcode (OPCODE_LOAD)
            );
          end
          3'b100: begin
            case (instr_i[12:10])
                3'b000: begin
                    // c.lbu rd', uimm(rs1')
                    instr_o = construct_i_type (
                        .imm (clb_imm),
                        .rs1 (c_rs1s),
                        .funct3 (3'b100),
                        .rd (c_rds),
                        .opcode (OPCODE_LOAD)
                      );
                end
                3'b001: begin
                    case (instr_i[6])
                        1'b0: begin
                            // c.lhu rs2', uimm(rs1')
                            instr_o = construct_i_type (
                                .imm (clhu_imm),
                                .rs1 (c_rs1s),
                                .funct3 (3'b101),
                                .rd (c_rds),
                                .opcode (OPCODE_LOAD)
                              );
                        end 
                        1'b1: begin
                            // c.lh rs2', uimm(rs1')
                            instr_o = construct_i_type (
                                .imm (clhu_imm),
                                .rs1 (c_rs1s),
                                .funct3 (3'b001),
                                .rd (c_rds),
                                .opcode (OPCODE_LOAD)
                              );
                        end
                    endcase
                end
                3'b010: begin
                    // c.sb rs2', uimm(rs1')
                    instr_o = construct_i_type (
                        .imm (clb_imm),
                        .rs1 (c_rs1s),
                        .funct3 (3'b000),
                        .rd (c_rds),
                        .opcode (OPCODE_STORE)
                      );
                end
                3'b011: begin
                    // c.sh rs2', uimm(rs1')
                    case (instr_i[6])
                        1'b0: begin
                            instr_o = construct_i_type (
                                .imm (clhu_imm),
                                .rs1 (c_rs1s),
                                .funct3 (3'b101),
                                .rd (c_rds),
                                .opcode (OPCODE_LOAD)
                              );
                        end 
                        1'b1: begin
                            illegal_instr_o = 1'b1;
                        end
                    endcase
                end
                default: illegal_instr_o = 1'b1;
            endcase
          end
          3'b101: begin
              illegal_instr_o = 1'b1;
          end
          3'b110: begin
            // c.sw -> sw rs2', rs1', cs_sw_imm
            instr_o = construct_s_type (
              .imm (cs_sw_imm),
              .rs2 (c_rs2s),
              .rs1 (c_rs1s),
              .funct3 (3'b010),
              .opcode (OPCODE_STORE)
            );
          end
          default: illegal_instr_o = 1'b1;
        endcase
      end
      2'b01: begin
        unique case (c_funct3)
          3'b000: begin
            // c.addi -> addi rd, rd, ci_imm
            // c.nop if rd = x0
            instr_o = construct_i_type (
              .imm (ci_imm),
              .rs1 (c_rd),
              .funct3 (3'b000),
              .rd (c_rd),
              .opcode (OPCODE_OP_IMM)
            );
          end
          3'b001: begin
            illegal_instr_o = 1'b1;
          end
          3'b010: begin
            // c.li -> addi rd, x0, ci_imm
            // hint if rd = x0
            instr_o = construct_i_type (
              .imm (ci_imm),
              .rs1 (0),
              .funct3 (3'b000),
              .rd (c_rd),
              .opcode (OPCODE_OP_IMM)
            );
          end
          3'b011: begin
            if (c_rd == 2) begin
              // c.addi16sp -> addi x2, x2, ci_addi16sp_imm
              instr_o = construct_i_type (
                .imm (ci_addi16sp_imm),
                .rs1 (2),
                .funct3 (3'b000),
                .rd (2),
                .opcode (OPCODE_OP_IMM)
              );
            end
            else begin
              // c.lui -> lui rd, ci_imm
              // hint if rd = x0
              instr_o = construct_u_type (
                .imm ({ {8{ci_imm[11]}}, ci_imm }),
                .rd (c_rd),
                .opcode (OPCODE_LUI)
              );
            end
            if (ci_imm == 0) illegal_instr_o = 1'b1;
          end
          3'b100: begin
            unique case (instr_i[11:10])
              2'b00: begin
                // c.srli -> srli rs1', rs1', ci_imm
                // hint if ci_imm = 0
                instr_o = construct_i_type (
                  .imm ({7'b0000000, ci_imm[4:0]}),
                  .rs1 (c_rs1s),
                  .funct3 (3'b101),
                  .rd (c_rs1s),
                  .opcode (OPCODE_OP_IMM)
                );
              end
              2'b01: begin
                // c.srai -> srai rs1', rs1', ci_imm
                // hint if ci_imm = 0
                instr_o = construct_i_type (
                  .imm ({7'b0100000, ci_imm[4:0]}),
                  .rs1 (c_rs1s),
                  .funct3 (3'b101),
                  .rd (c_rs1s),
                  .opcode (OPCODE_OP_IMM)
                );
              end
              2'b10: begin
                // c.andi -> andi rs1', rs1', imm
                instr_o = construct_i_type (
                  .imm (ci_imm),
                  .rs1 (c_rs1s),
                  .funct3 (3'b111),
                  .rd (c_rs1s),
                  .opcode (OPCODE_OP_IMM)
                );
              end
              2'b11: begin
                unique case ({instr_i[12], instr_i[6:5]})
                  3'b000: begin
                    // c.sub -> sub rs1', rs1', rs2'
                    instr_o = construct_r_type (
                      .funct7 (7'b0100000),
                      .rs2 (c_rs2s),
                      .rs1 (c_rs1s),
                      .funct3 (3'b000),
                      .rd (c_rs1s),
                      .opcode (OPCODE_OP)
                    );
                  end
                  3'b001: begin
                    // c.xor -> xor rs1', rs1', rs2'
                    instr_o = construct_r_type (
                      .funct7 (7'b0000000),
                      .rs2 (c_rs2s),
                      .rs1 (c_rs1s),
                      .funct3 (3'b100),
                      .rd (c_rs1s),
                      .opcode (OPCODE_OP)
                    );
                  end
                  3'b010: begin
                    // c.or  -> or  rs1', rs1', rs2'
                    instr_o = construct_r_type (
                      .funct7 (7'b0000000),
                      .rs2 (c_rs2s),
                      .rs1 (c_rs1s),
                      .funct3 (3'b110),
                      .rd (c_rs1s),
                      .opcode (OPCODE_OP)
                    );
                  end
                  3'b011: begin
                    // c.and -> and rs1', rs1', rs2'
                    instr_o = construct_r_type (
                      .funct7 (7'b0000000),
                      .rs2 (c_rs2s),
                      .rs1 (c_rs1s),
                      .funct3 (3'b111),
                      .rd (c_rs1s),
                      .opcode (OPCODE_OP)
                    );
                  end
                  3'b110: begin
                    // c.mul -> mul rs1', rs1', rs2'
                    instr_o = construct_r_type (
                        .funct7 (7'b0000001),
                        .rs2 (c_rs2s),
                        .rs1 (c_rs1s),
                        .funct3 (3'b000),
                        .rd (c_rs1s),
                        .opcode (OPCODE_OP)
                      );
                  end
                  3'b111: begin
                    case (instr_i[4:2])
                        3'b000: begin
                            // c.zext.b rs1', rs1' 
                            instr_o = construct_i_type (
                                .imm(12'h0ff),
                                .rs1 (c_rs1s),
                                .funct3 (3'b111),
                                .rd (c_rs1s),
                                .opcode (OPCODE_OP_IMM)
                              );
                        end
                        3'b001: begin
                            // c.sext.b rs1', rs1'
                            instr_o = construct_i_type (
                                .imm(12'b011000000100),
                                .rs1 (c_rs1s),
                                .funct3 (3'b001),
                                .rd (c_rs1s),
                                .opcode (OPCODE_OP_IMM)
                              );
                        end
                        3'b010: begin
                            // c.zext.h rs1', rs1'
                            instr_o = construct_r_type (
                                .funct7(7'b0000100),
                                .rs2(5'd0),
                                .rs1 (c_rs1s),
                                .funct3 (3'b100),
                                .rd (c_rs1s),
                                .opcode (OPCODE_OP)
                              );
                        end
                        3'b011: begin
                            // c.sext.h rs1', rs1'
                            instr_o = construct_i_type (
                                .imm(12'b011000000101),
                                .rs1 (c_rs1s),
                                .funct3 (3'b001),
                                .rd (c_rs1s),
                                .opcode (OPCODE_OP_IMM)
                              );
                        end
                        3'b101: begin
                            // c.not rs1', rs1'
                            instr_o = construct_i_type (
                                .imm(12'hfff),
                                .rs1 (c_rs1s),
                                .funct3 (3'b100),
                                .rd (c_rs1s),
                                .opcode (OPCODE_OP_IMM)
                              );
                        end
                        default: illegal_instr_o = 1'b1;
                    endcase
                  end
                  default: illegal_instr_o = 1'b1;
                endcase
              end
            endcase
          end
          3'b101: begin
            // c.j -> jal x0, cj_imm
            instr_o = construct_j_type (
              .imm (cj_imm),
              .rd (0),
              .opcode (OPCODE_JAL)
            );
          end
          3'b110: begin
            // c.beqz -> beq rs1', x0, cb_imm
            instr_o = construct_b_type (
              .imm (cb_imm),
              .rs2 (0),
              .rs1 (c_rs1s),
              .funct3 (3'b000),
              .opcode (OPCODE_BRANCH)
            );
          end
          3'b111: begin
            // c.bnez -> bne rs1', x0, cb_imm
            instr_o = construct_b_type (
              .imm (cb_imm),
              .rs2 (0),
              .rs1 (c_rs1s),
              .funct3 (3'b001),
              .opcode (OPCODE_BRANCH)
            );
          end
        endcase
      end
      2'b10: begin
        unique case (c_funct3)
          3'b000: begin
            // c.slli -> slli rd, rd, ci_imm
            // hint if ci_imm = 0 or rd = x0
            instr_o = construct_i_type (
              .imm ({6'b000000, ci_imm[5:0]}),
              .rs1 (c_rd),
              .funct3 (3'b001),
              .rd (c_rd),
              .opcode (OPCODE_OP_IMM)
            );
          end
          3'b001: begin
            illegal_instr_o = 1'b1;
          end
          3'b010: begin
            // c.lwsp -> lw rd, x2, ci_lwsp_imm
            instr_o = construct_i_type (
              .imm (ci_lwsp_imm),
              .rs1 (2),
              .funct3 (3'b010),
              .rd (c_rd),
              .opcode (OPCODE_LOAD)
            );
            if (c_rd == 0) illegal_instr_o = 1'b1;
          end
          3'b011: begin
            illegal_instr_o = 1'b1;
          end
          3'b100: begin
            if (instr_i[12] == 0) begin
              if (c_rs2 == 0) begin
                // c.jr -> jalr x0, rs1, 0
                instr_o = construct_i_type (
                  .imm (0),
                  .rs1 (c_rs1),
                  .funct3 (3'b000),
                  .rd (0),
                  .opcode (OPCODE_JALR)
                );
                if (c_rs1 == 0) illegal_instr_o = 1'b1;
              end else begin
                // c.mv -> add rd, x0, rs2
                // hint if rd = x0
                instr_o = construct_r_type (
                  .funct7 (7'b0000000),
                  .rs2 (c_rs2),
                  .rs1 (0),
                  .funct3 (3'b000),
                  .rd (c_rd),
                  .opcode (OPCODE_OP)
                );
              end
            end else begin
              if (c_rs2 == 0) begin
                if (c_rs1 == 0) begin
                  // c.ebreak -> ebreak
                  instr_o = 32'b000000000001_00000_000_00000_1110011;
                end else begin
                  // c.jalr  -> jalr x1, rs1, 0
                  instr_o = construct_i_type (
                    .imm (0),
                    .rs1 (c_rs1),
                    .funct3 (3'b000),
                    .rd (1),
                    .opcode (OPCODE_JALR)
                  );
                end
              end else begin
                // c.add -> add rd, rd, rs2
                // hint if rd = x0
                instr_o = construct_r_type (
                  .funct7 (7'b0000000),
                  .rs2 (c_rs2),
                  .rs1 (c_rd),
                  .funct3 (3'b000),
                  .rd (c_rd),
                  .opcode (OPCODE_OP)
                );
              end
            end
          end
          3'b101: begin
            illegal_instr_o = 1'b1;
          end
          3'b110: begin
            // c.swsp -> sw rs2, x2, css_swsp_imm
            instr_o = construct_s_type (
              .imm (css_swsp_imm),
              .rs1 (2),
              .rs2 (c_rs2),
              .funct3 (3'b010),
              .opcode (OPCODE_STORE)
            );
          end
          3'b111: begin
            illegal_instr_o = 1'b1;
          end
        endcase
      end
      default: instr_o = 'x;
    endcase
  end

endmodule
