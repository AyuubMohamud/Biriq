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

module csr #(
    parameter [31:0] HARTID = 0,
    parameter PMP_REGS = 8,
    parameter ENABLE_CUSTOM = 1
) (
    input   wire logic                          core_clock_i,

    input   wire logic [31:0]                   csr_data_i,
    input   wire logic [11:0]                   csr_address_i,
    input   wire logic [1:0]                    csr_opcode_i,
    input   wire logic                          csr_we_i,
    input   wire logic                          csr_valid_i,
    input   wire logic                          csr_mret_i,
    input   wire logic                          csr_take_exception,
    input   wire logic                          csr_take_interrupt,
    input   wire logic [29:0]                   csr_epc_i,
    input   wire logic [31:0]                   csr_mtval_i,
    input   wire logic [3:0]                    csr_mcause_i,
    input   wire logic                          csr_msip_i,
    input   wire logic                          csr_mtip_i,
    input   wire logic                          csr_meip_i,
    input   wire logic                          csr_inc_commit0_i,
    input   wire logic                          csr_inc_commit1_i,
    input   wire logic [24:0]                   csr_i_addr_i,
    input   wire logic [24:0]                   csr_d_addr_i,
    input   wire logic                          csr_d_write_i,

    output       logic                          csr_done_o,
    output       logic                          csr_excp_o,
    output       logic [31:0]                   csr_data_o,
    output  wire logic [2:0]                    csr_mip_o,
    output  wire logic                          csr_mie_o,
    output  wire logic                          csr_mprv_o,
    output  wire logic                          csr_tw_o,
    output  wire logic                          csr_real_priv_o,
    output  wire logic [29:0]                   csr_mepc_o,
    output  wire logic [31:0]                   csr_mtvec_o,
    output  wire logic                          csr_en_br_pred_o,
    output  wire logic                          csr_en_ctr_ovr_o,
    output  wire logic                          csr_ctr_val_o,
    output  wire logic                          csr_i_kill_o,
    output  wire logic                          csr_d_kill_o,
    output  wire logic                          csr_weak_io_o,
    output  wire logic [1:0]                    csr_cbie_o,
    output  wire logic                          csr_cbcfe_o,
    output  wire logic                          csr_cbze_o,
    output  wire logic                          csr_ld_rdr_o
);
    //! CSR Address Definitions (non pmp)
    localparam MVENDORID = 12'hF11;
    localparam MARCHID = 12'hF12;
    localparam MIMPID = 12'hF13;
    localparam MHARTID = 12'hF14;
    localparam MCONFIGPTR = 12'hF15;
    localparam MSTATUS = 12'h300; 
    localparam MISA = 12'h301;
    localparam MIE = 12'h304;
    localparam MTVEC = 12'h305;
    localparam MCOUNTEREN = 12'h306;
    localparam MSTATUSH = 12'h310;
    localparam MSCRATCH = 12'h340;
    localparam MEPC = 12'h341;
    localparam MCAUSE = 12'h342;
    localparam MTVAL = 12'h343;
    localparam MIP = 12'h344;
    localparam MENVCFG = 12'h30A;
    localparam MENVCFGH = 12'h31A;
    localparam CYCLE = 12'hC00;
    localparam CYCLEH = 12'hC80;
    localparam MCYCLE = 12'hB00;
    localparam MCYCLEH = 12'hB80;
    localparam INSTRET = 12'hC01;
    localparam INSTRETH = 12'hC81;
    localparam MINSTRET = 12'hB02;
    localparam MINSTRETH = 12'hB82;
    localparam MCOUNTERINHIBIT = 12'h320;
    localparam MAUX = 12'h7C0;

    // CSR registers (non pmp)
    reg current_privilege_mode = 1'b1; // Initially at 1'b1
    reg [5:0] mstatus = 0;
    reg [2:0] mie = 0;
    reg [31:0] mtvec = 0;
    reg [2:0] mcounteren = 0; 
    reg [31:0] mscratch = 0; 
    reg [29:0] mepc = 0; 
    reg [4:0] mcause = 0; 
    reg [31:0] mtval = 0; 
    reg [2:0] mip = 0; 
    reg [3:0] menvcfg = 0; // fences are already implemented as total, RO ZERO
    // USER accessible CSRs
    reg [63:0] cycle = 0;
    reg [63:0] instret = 0;
    reg [1:0] mcountinhibit = 0; 
    // Vendor-specific CSRs
    reg [4:0] maux = 5'b10100;

    logic [31:0] read_data;
    logic csr_exists;
    wire [31:0] new_data;
    logic [31:0] pmp_data;
    logic pmp_exists;
    wire [31:0] bit_sc;

    generate if (PMP_REGS==0) begin : _no_pmp
        assign csr_i_kill_o = 0;
        assign csr_d_kill_o = 0;
        assign pmp_exists = 0;
        assign pmp_data = 0;
    end else if (PMP_REGS>0) begin : _gen_pmp
        wire mpu_we;
        assign mpu_we = csr_we_i&current_privilege_mode&csr_valid_i;
        wire dmode = current_privilege_mode&!csr_mprv_o;
        mpu #(PMP_REGS) mpu0 (
            .core_clock_i(core_clock_i),
            .mpu_address_i(csr_address_i),
            .mpu_data_i(new_data),
            .mpu_we_i(mpu_we),
            .mpu_data_o(pmp_data),
            .mpu_exists_o(pmp_exists),
            .mpu_i_addr_i(csr_i_addr_i),
            .mpu_i_mmode_i(current_privilege_mode),
            .mpu_i_kill_o(csr_i_kill_o),
            .mpu_d_addr_i(csr_d_addr_i),
            .mpu_d_mmode_i(dmode),
            .mpu_d_write_i(csr_d_write_i),
            .mpu_d_kill_o(csr_d_kill_o)
        );
    end endgenerate

    always_comb begin
        case (csr_address_i)
            MVENDORID: begin read_data = 32'h0; csr_exists = 1; end
            MIMPID: begin read_data = 32'h9;csr_exists = 1; end
            MARCHID: begin read_data = 32'h0;csr_exists = 1; end
            MHARTID: begin read_data = HARTID;csr_exists = 1; end
            MCONFIGPTR: begin read_data = 32'h0;csr_exists = 1; end
            MSTATUS: begin read_data = {14'h0, mstatus[4], 4'd0, mstatus[3:2], 3'd0, mstatus[1], 3'd0, mstatus[0], 3'd0};csr_exists = 1; end
            MISA: begin read_data = {8'h40, ENABLE_CUSTOM==0 ? 1'b0 : 1'b1, 3'b001, 20'h01101};csr_exists = 1; end
            MIE: begin read_data = {20'h0,mie[2], 3'd0, mie[1], 3'd0, mie[0], 3'd0};csr_exists = 1; end
            MIP: begin read_data = {20'h0,mip[2]|csr_meip_i, 3'd0, mip[1]|csr_mtip_i, 3'd0, mip[0]|csr_msip_i, 3'd0};csr_exists = 1;end
            MTVEC: begin read_data = mtvec;csr_exists = 1;end
            MTVAL: begin read_data = mtval;csr_exists = 1;end
            MSTATUSH: begin read_data = 32'h0;csr_exists = 1;end
            MENVCFGH : begin read_data = 32'h0; csr_exists = 1; end
            MENVCFG: begin read_data = {24'h0, menvcfg, 4'h0}; csr_exists = 1; end
            MCAUSE: begin read_data = {mcause[4], 27'h0,mcause[3:0]};csr_exists = 1;end
            MSCRATCH: begin read_data = mscratch;csr_exists = 1;end
            MEPC: begin read_data = {mepc,2'b00};csr_exists = 1;end
            MCOUNTERINHIBIT: begin read_data = {29'h0,mcountinhibit[1],1'b0,mcountinhibit[0]};csr_exists = 1;end
            MCYCLE: begin read_data = cycle[31:0];csr_exists = 1;end
            MCYCLEH: begin read_data = cycle[63:32];csr_exists = 1;end
            MINSTRET: begin read_data = instret[31:0];csr_exists = 1;end
            MINSTRETH: begin read_data = instret[63:32];csr_exists = 1;end
            MCOUNTEREN: begin read_data = {29'h0,mcounteren[2],mcounteren[1],mcounteren[0]}; csr_exists = 1; end
            CYCLE: begin read_data = cycle[31:0];csr_exists = (current_privilege_mode||(mcounteren[0]&!current_privilege_mode));end
            CYCLEH: begin read_data = cycle[63:32];csr_exists = (current_privilege_mode||(mcounteren[0]&!current_privilege_mode));end
            INSTRET: begin read_data = instret[31:0];csr_exists = (current_privilege_mode||(mcounteren[2]&!current_privilege_mode));end
            INSTRETH: begin read_data = instret[63:32];csr_exists = (current_privilege_mode||(mcounteren[2]&!current_privilege_mode));end
            MAUX: begin read_data = {27'd0, maux}; csr_exists = 1; end
            default: begin
                read_data = pmp_data; csr_exists = pmp_exists;
            end
        endcase
    end

    always_ff @(posedge core_clock_i) begin
        if ((csr_mret_i|csr_take_exception|csr_take_interrupt)) begin
            casez ({csr_mret_i,csr_take_exception, csr_take_interrupt})
                3'b100: begin : mret
                    if (current_privilege_mode) begin
                        // MAP: 17 -> 4, 12:11 -> 3:2 7 -> 1 3 -> 0
                        mstatus[0] <= mstatus[1]; // mpie->mie
                        mstatus[3:2] <= 2'b00; // machine mode is least supported mode
                        current_privilege_mode <= mstatus[3]&mstatus[2];
                        mstatus[1] <= 1;
                        mstatus[4] <= mstatus[4]&(mstatus[3:2]==2'b11); // mprv -> 0 when mpp!=M
                    end
                end
                3'b001: begin : Interrupt
                    mstatus[1] <= 1'b1;
                    mstatus[3:2] <= {current_privilege_mode,current_privilege_mode};
                    mstatus[0] <= 0; // mie
                    mepc<=csr_epc_i;
                    mcause<={1'b1, csr_mcause_i[3:0]};
                    mtval <= 0;
                    current_privilege_mode <= 1;
                end
                3'b010: begin : Exception
                    mstatus[1] <= mstatus[0];
                    mstatus[3:2] <= {current_privilege_mode,current_privilege_mode};
                    mstatus[0] <= 0;
                    mepc<=csr_epc_i;
                    mcause<={1'b0,csr_mcause_i[3:0]};
                    mtval <= csr_mtval_i;current_privilege_mode <= 1;
                end
                default: begin
                    
                end
            endcase
            // MAP: 17 -> 4, 12:11 -> 3:2 7 -> 1 mstatus -> 0
        end else if (csr_valid_i &&  csr_we_i && (current_privilege_mode)) begin
            case (csr_address_i)
                MSTATUS: begin
                    mstatus[5] <= new_data[21];
                    mstatus[4] <= new_data[17];
                    mstatus[3:2] <= {new_data[12],new_data[12]};
                    mstatus[1] <= new_data[7];
                    mstatus[0] <= new_data[3]; 
                end
                MCAUSE: begin
                    mcause <= {new_data[31],new_data[3:0]};
                end
                MEPC: begin
                    mepc <= new_data[31:2];
                end
                MTVAL: begin
                    mtval <= new_data;
                end
                default: begin
                    
                end
            endcase
        end
    end

    always_ff @(posedge core_clock_i) begin
        if (csr_valid_i&& csr_we_i&&(current_privilege_mode)) begin
            case (csr_address_i)
                MSCRATCH: begin
                    mscratch <= new_data;
                end
                MTVEC: begin
                    mtvec[31:2] <= new_data[31:2];
                    mtvec[1:0] <= new_data[1:0] == 2'b00 ? 2'b00:
                                  new_data[1:0] == 2'b01 ? 2'b01:
                                  2'b00;
                end
                MIE: begin
                    mie[2] <= new_data[11];
                    mie[1] <=  new_data[7];
                    mie[0] <=  new_data[3];
                end
                MCOUNTERINHIBIT: begin
                    mcountinhibit[1] <= new_data[2];
                    mcountinhibit[0] <= new_data[0];
                end
                MCOUNTEREN: begin
                    mcounteren[0] <= new_data[0];
                    mcounteren[1] <= new_data[1];
                    mcounteren[2] <= new_data[2];
                end
                MENVCFG: begin
                    menvcfg[1:0] <= new_data[5:4];
                    menvcfg[2] <= new_data[6];
                    menvcfg[3] <= new_data[7];
                end
                default: begin
                    
                end
            endcase
        end
    end

    always_ff @(posedge core_clock_i) begin
        if (csr_valid_i&&csr_we_i&&(current_privilege_mode)&&(csr_address_i==MCYCLE)) begin
            cycle[31:0] <= new_data;
        end 
        else if (csr_valid_i&&csr_we_i&&(current_privilege_mode)&&(csr_address_i==MCYCLEH)) begin
            cycle[63:32] <= new_data;
        end else if (!mcountinhibit[0]) begin
            cycle <= cycle + 1;
        end
    end

    always_ff @(posedge core_clock_i) begin
        if (csr_valid_i&&csr_we_i&&(current_privilege_mode)&&(csr_address_i==MINSTRET)) begin
            instret[31:0] <= new_data;
        end 
        else if (csr_valid_i&&csr_we_i&&(current_privilege_mode)&&(csr_address_i==MINSTRETH)) begin
            instret[63:32] <= new_data;
        end else if ((csr_inc_commit0_i|csr_inc_commit1_i)&!mcountinhibit[1]) begin
            instret <= instret + {csr_inc_commit0_i&csr_inc_commit1_i ? 64'd2 : 64'd1};
        end
    end

    always_ff @(posedge core_clock_i) begin
        if (csr_valid_i&&csr_we_i&&(csr_address_i==MAUX)&&current_privilege_mode) begin
            maux <= new_data[4:0];
        end
    end

    always_ff @(posedge core_clock_i) begin
        csr_data_o <= read_data;
    end
    
    initial csr_done_o = 0;
    always_ff @(posedge core_clock_i) begin
        if (csr_valid_i) begin
            csr_done_o <= 1;
            csr_excp_o <= ~((csr_exists&&({current_privilege_mode,current_privilege_mode}>=csr_address_i[9:8])&&!(csr_we_i&&(&csr_address_i[11:10]))));
        end
        else begin
            csr_done_o <= 0;
        end
    end

    assign bit_sc = 1 << csr_data_i[4:0];
    assign new_data = csr_opcode_i==2'b01 ? csr_data_i : csr_opcode_i==2'b10 ? read_data|bit_sc : read_data&~(bit_sc);
    assign csr_mepc_o = mepc;
    assign csr_mtvec_o = mtvec;
    assign csr_mie_o = mstatus[0];
    assign csr_tw_o = mstatus[5];
    assign csr_en_br_pred_o = maux[2];
    assign csr_en_ctr_ovr_o = maux[1];
    assign csr_ctr_val_o = maux[0];
    assign csr_weak_io_o = maux[3];
    assign csr_real_priv_o = current_privilege_mode;
    assign csr_mip_o = {csr_meip_i, csr_mtip_i, csr_msip_i}&{mie[2], mie[1], mie[0]};
    assign csr_mprv_o = mstatus[4];
    assign csr_cbie_o = menvcfg[1:0];
    assign csr_cbcfe_o = menvcfg[2];
    assign csr_cbze_o = menvcfg[3];
    assign csr_ld_rdr_o = maux[4];
endmodule
