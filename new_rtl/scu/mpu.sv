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
module mpu #(
    parameter PMP_REGS = 8,
    parameter ENABLE_SMEPMP = 0
) (
    input wire logic core_clock_i,

    input wire logic [11:0] mpu_address_i,
    input wire logic [31:0] mpu_data_i,
    input wire logic        mpu_we_i,

    output logic [31:0] mpu_data_o,
    output logic        mpu_exists_o,

    input  wire logic [24:0] mpu_i_addr_i,
    input  wire logic        mpu_i_mmode_i,
    output wire logic        mpu_i_kill_o,

    input  wire logic [24:0] mpu_d_addr_i,
    input  wire logic        mpu_d_mmode_i,
    input  wire logic        mpu_d_write_i,
    output wire logic        mpu_d_kill_o
);
  localparam PMPCFG_BASE = 12'h3a0;
  localparam PMPADR_BASE = 12'h3b0;
  localparam PMPADR_END = 12'h3f0;
  localparam PMPCFG_NUM = PMP_REGS / 4;

  initial begin
    if ((PMP_REGS % 4 != 0) || (PMP_REGS > 64)) begin
      $fatal("Invalid configuration for PMP!");
    end
  end

  generate
    if (PMP_REGS == 0) begin : _no_pmp
      assign mpu_d_kill_o = 0;
      assign mpu_i_kill_o = 0;
      assign mpu_exists_o = 0;
    end else begin : _else_gen_pmp
      reg [PMP_REGS-1:0] pmp_l;
      reg [PMP_REGS-1:0] pmp_a;
      reg [PMP_REGS-1:0] pmp_x;
      reg [PMP_REGS-1:0] pmp_w;
      reg [PMP_REGS-1:0] pmp_r;
      reg [25:0] pmp_addr[0:PMP_REGS-1];
      reg [24:0] pmp_mask[0:PMP_REGS-1];
      reg [24:0] pmp_match[0:PMP_REGS-1];
      initial begin
        for (integer i = 0; i < PMP_REGS; i++) begin
          pmp_l[i] = 0;
          pmp_a[i] = 0;
          pmp_x[i] = 0;
          pmp_w[i] = 0;
          pmp_r[i] = 0;
          pmp_addr[i] = 0;
          pmp_mask[i] = 0;
          pmp_match[i] = 0;
        end
      end

      logic imatch;
      logic i_pmp_l;
      logic i_pmp_x;
      always_comb begin
        imatch  = '0;
        i_pmp_l = 'x;
        i_pmp_x = 'x;
        for (integer i = 0; i < PMP_REGS; i++) begin
          if (!imatch & (pmp_match[i]) == (mpu_i_addr_i & pmp_mask[i]) & pmp_a[i]) begin
            i_pmp_l = pmp_l[i];
            i_pmp_x = pmp_x[i];
            imatch  = 1;
          end
        end
      end
      assign mpu_i_kill_o = mpu_i_mmode_i ? (i_pmp_l & imatch & !i_pmp_x) : !(imatch & i_pmp_x);

      logic dmatch;
      logic d_pmp_l;
      logic d_pmp_w;
      logic d_pmp_r;
      always_comb begin
        dmatch  = '0;
        d_pmp_l = 'x;
        d_pmp_w = 'x;
        d_pmp_r = 'x;
        for (integer i = 0; i < PMP_REGS; i++) begin
          if (!dmatch & (pmp_match[i]) == (mpu_d_addr_i & pmp_mask[i]) & pmp_a[i]) begin
            d_pmp_l = pmp_l[i];
            d_pmp_w = pmp_w[i];
            d_pmp_r = pmp_r[i];
            dmatch  = 1;
          end
        end
      end
      assign mpu_d_kill_o = mpu_d_mmode_i ? (d_pmp_l&dmatch&((mpu_d_write_i&!d_pmp_w)||(!mpu_d_write_i&!d_pmp_r))) : (!dmatch)|(!(dmatch&((mpu_d_write_i&d_pmp_w)||(!mpu_d_write_i&d_pmp_r))));

      wire [29:0] mask;
      wire [29:0] match;
      pmpdec decode0 (
          {mpu_data_i[29:4], 4'b1111},
          mask,
          match
      );

      always_ff @(posedge core_clock_i) begin
        for (integer i = 0; i < PMP_REGS; i++) begin
          if (mpu_we_i&!pmp_l[i]&&(mpu_address_i[11:4]==8'h3b)&!mpu_address_i[3]&(i[2:0]==mpu_address_i[2:0])&&mpu_i_mmode_i)
          begin
            pmp_addr[i]  <= {mpu_data_i[29:4]};
            pmp_mask[i]  <= mask[29:5];
            pmp_match[i] <= match[29:5];
          end
        end
        for (integer i = 0; i < PMPCFG_NUM; i++) begin
          if (!pmp_l[i*4 + 0] && mpu_we_i && (mpu_address_i[11:4]==8'h3a) && (mpu_address_i[3:0]==i[3:0]) && mpu_i_mmode_i)
          begin
            pmp_l[i*4+0] <= mpu_data_i[7];
            pmp_a[i*4+0] <= &mpu_data_i[4:3];
            pmp_x[i*4+0] <= mpu_data_i[2];
            pmp_w[i*4+0] <= mpu_data_i[1];
            pmp_r[i*4+0] <= mpu_data_i[0];
          end

          if (!pmp_l[i*4 + 1] && mpu_we_i && (mpu_address_i[11:4]==8'h3a) && (mpu_address_i[3:0]==i[3:0]) && mpu_i_mmode_i)
          begin
            pmp_l[i*4+1] <= mpu_data_i[15];
            pmp_a[i*4+1] <= &mpu_data_i[12:11];
            pmp_x[i*4+1] <= mpu_data_i[10];
            pmp_w[i*4+1] <= mpu_data_i[9];
            pmp_r[i*4+1] <= mpu_data_i[8];
          end

          if (!pmp_l[i*4 + 2] && mpu_we_i && (mpu_address_i[11:4]==8'h3a) && (mpu_address_i[3:0]==i[3:0]) && mpu_i_mmode_i)
          begin
            pmp_l[i*4+2] <= mpu_data_i[23];
            pmp_a[i*4+2] <= &mpu_data_i[20:19];
            pmp_x[i*4+2] <= mpu_data_i[18];
            pmp_w[i*4+2] <= mpu_data_i[17];
            pmp_r[i*4+2] <= mpu_data_i[16];
          end

          if (!pmp_l[i*4 + 3] && mpu_we_i && (mpu_address_i[11:4]==8'h3a) && (mpu_address_i[3:0]==i[3:0]) && mpu_i_mmode_i)
          begin
            pmp_l[i*4+3] <= mpu_data_i[31];
            pmp_a[i*4+3] <= &mpu_data_i[28:27];
            pmp_x[i*4+3] <= mpu_data_i[26];
            pmp_w[i*4+3] <= mpu_data_i[25];
            pmp_r[i*4+3] <= mpu_data_i[24];
          end
        end
      end
      logic [31:0] cfg_read_data;
      logic cfg_exists;
      logic [31:0] addr_read_data;
      logic addr_exists;
      always_comb begin
        cfg_read_data = '0;
        for (integer i = 0; i < PMPCFG_NUM; i++) begin
          if (i[3:0] == mpu_address_i[3:0]) begin
            cfg_read_data = {
              pmp_l[i*4+3],
              2'b00,
              pmp_a[i*4+3],
              pmp_a[i*4+3],
              pmp_x[i*4+3],
              pmp_w[i*4+3],
              pmp_r[i*4+3],
              pmp_l[i*4+2],
              2'b00,
              pmp_a[i*4+2],
              pmp_a[i*4+2],
              pmp_x[i*4+2],
              pmp_w[i*4+2],
              pmp_r[i*4+2],
              pmp_l[i*4+1],
              2'b00,
              pmp_a[i*4+1],
              pmp_a[i*4+1],
              pmp_x[i*4+1],
              pmp_w[i*4+1],
              pmp_r[i*4+1],
              pmp_l[i*4+0],
              2'b00,
              pmp_a[i*4+0],
              pmp_a[i*4+0],
              pmp_x[i*4+0],
              pmp_w[i*4+0],
              pmp_r[i*4+0]
            };
          end
        end
        cfg_exists = (PMPCFG_BASE <= mpu_address_i) && (PMPADR_BASE > mpu_address_i);
      end

      always_comb begin
        addr_read_data = '0;
        for (integer i = 0; i < PMP_REGS; i++) begin
          if ((PMPADR_BASE + i[11:0]) == mpu_address_i) begin
            addr_read_data = {2'b00, pmp_addr[i], 4'b1111};
          end
        end
        addr_exists = (PMPADR_BASE <= mpu_address_i) && (PMPADR_END > mpu_address_i);
      end

      assign mpu_exists_o = (cfg_exists | addr_exists) && mpu_i_mmode_i;
      assign mpu_data_o   = cfg_exists ? cfg_read_data : addr_read_data;
    end
  endgenerate
endmodule
