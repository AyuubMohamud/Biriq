// This is the scheduler for port1, simple 1-clk integer instrctions and branch integer instructions.
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
//  | PARTICULAR PURPOSE. Please see the CERN-OHL-S v2 for applicable conditions.           |
//  |                                                                                       |
//  | Source location: https://github.com/AyuubMohamud/Biriq                                |
//  |                                                                                       |
//  | As per CERN-OHL-W v2 section 4, should You produce hardware based on this             |
//  | source, You must where practicable maintain the Source Location visible               |
//  | in the same manner as is done within this source.                                     |
//  |                                                                                       |
//  -----------------------------------------------------------------------------------------

`default_nettype none

module unifiedIntQueue (
    input   wire logic          cpu_clk_i,
    input   wire logic          flush_i,
    
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

    output  logic               alu2_vld_o,
    output  logic      [17:0]   alu2_data_o,
    output  logic               alu_vld_o,
    output  logic      [17:0]   alu_data_o,

    input   wire logic [5:0]    eu0_wk,
    input   wire logic          eu0_vld,
 
    input   wire logic [5:0]    eu1_wk,
    input   wire logic          eu1_vld,

    input   wire logic [5:0]    eu2_wk,
    input   wire logic          eu2_vld
);
    reg [5:0] ShQueueCAM1 [0:11]; // Store Data
    reg [5:0] ShQueueCAM0 [0:11];
    reg [5:0] ShQueueRAM [0:11]; // ROB ID
    reg [11:0] branch;
    reg [11:0] vld = 0;
    reg [11:0] AV1;
    reg [11:0] AV2;
    wire [11:0] AV1l;
    wire [11:0] AV2l;//
    wire [11:0] shift;//
    wire [11:0] shift_two ;//

    wire [11:0] data_rdy;//

    wire [11:0] vldl;//
    logic [11:0] ddec;
    logic [11:0] ddec2;
    assign shift[0] = !vld[0];
    assign shift[1] = !(vld[1] & vld[0]);
    assign shift[2] = !(vld[2] & vld[1] & vld[0]);
    assign shift[3] = !(vld[3] & vld[2] & vld[1] & vld[0]);
    assign shift[4] = !(vld[4] & vld[3] & vld[2] & vld[1] & vld[0]);
    assign shift[5] = !(vld[5] & vld[4] & vld[3] & vld[2] & vld[1] & vld[0]);
    assign shift[6] = !(vld[6] & vld[5] & vld[4] & vld[3] & vld[2] & vld[1] & vld[0]);
    assign shift[7] = !(vld[7] & vld[6] & vld[5] & vld[4] & vld[3] & vld[2] & vld[1] & vld[0]);
    assign shift[8] = !(vld[8] & vld[7] & vld[6] & vld[5] & vld[4] & vld[3] & vld[2] & vld[1] & vld[0]);
    assign shift[9] = !(vld[9] & vld[8] & vld[7] & vld[6] & vld[5] & vld[4] & vld[3] & vld[2] & vld[1] & vld[0]);
    assign shift[10] = !(vld[10]&vld[9] & vld[8] & vld[7] & vld[6] & vld[5] & vld[4] & vld[3] & vld[2] & vld[1] & vld[0]);
    assign shift[11] = !(vld[11]&vld[10]&vld[9] & vld[8] & vld[7] & vld[6] & vld[5] & vld[4] & vld[3] & vld[2] & vld[1] & vld[0]);
    assign shift_two[0] = !vld[1] & shift[0];
    assign shift_two[1] = (!vld[1]&shift[0])|(!vld[2]&shift[1]);
    assign shift_two[2] = (!vld[1]&shift[0])|(!vld[2]&shift[1])|(!vld[3]&shift[2]);
    assign shift_two[3] = (!vld[1]&shift[0])|(!vld[2]&shift[1])|(!vld[3]&shift[2])|(!vld[4]&shift[3]);
    assign shift_two[4] = (!vld[1]&shift[0])|(!vld[2]&shift[1])|(!vld[3]&shift[2])|(!vld[4]&shift[3])|(!vld[5]&shift[4]);
    assign shift_two[5] = (!vld[1]&shift[0])|(!vld[2]&shift[1])|(!vld[3]&shift[2])|(!vld[4]&shift[3])|(!vld[5]&shift[4])|(!vld[6]&shift[5]);
    assign shift_two[6] = (!vld[1]&shift[0])|(!vld[2]&shift[1])|(!vld[3]&shift[2])|(!vld[4]&shift[3])|(!vld[5]&shift[4])|(!vld[6]&shift[5])|(!vld[7]&shift[6]);
    assign shift_two[7] = (!vld[1]&shift[0])|(!vld[2]&shift[1])|(!vld[3]&shift[2])|(!vld[4]&shift[3])|(!vld[5]&shift[4])|(!vld[6]&shift[5])|(!vld[7]&shift[6])|(!vld[8]&shift[7]);
    assign shift_two[8] = (!vld[1]&shift[0])|(!vld[2]&shift[1])|(!vld[3]&shift[2])|(!vld[4]&shift[3])|(!vld[5]&shift[4])|(!vld[6]&shift[5])|(!vld[7]&shift[6])|(!vld[8]&shift[7])|(!vld[9]&shift[8]);
    assign shift_two[9] = (!vld[1]&shift[0])|(!vld[2]&shift[1])|(!vld[3]&shift[2])|(!vld[4]&shift[3])|(!vld[5]&shift[4])|(!vld[6]&shift[5])|(!vld[7]&shift[6])|(!vld[8]&shift[7])|(!vld[9]&shift[8])|(shift[9]&!vld[10]);
    assign shift_two[10] = (!vld[1]&shift[0])|(!vld[2]&shift[1])|(!vld[3]&shift[2])|(!vld[4]&shift[3])|(!vld[5]&shift[4])|(!vld[6]&shift[5])|(!vld[7]&shift[6])|(!vld[8]&shift[7])|(!vld[9]&shift[8])|(shift[9]&!vld[10])|(shift[10]&!vld[11]);
    assign shift_two[11] = (!vld[1]&shift[0])|(!vld[2]&shift[1])|(!vld[3]&shift[2])|(!vld[4]&shift[3])|(!vld[5]&shift[4])|(!vld[6]&shift[5])|(!vld[7]&shift[6])|(!vld[8]&shift[7])|(!vld[9]&shift[8])|(shift[9]&!vld[10])|(shift[10]&!vld[11]);


    assign p0_busy_o = !shift[11];
    assign p1_busy_o = !shift_two[11];

    wire [11:0] CMPy;
    wire [11:0] CMPs;
    generate 
        for (genvar i = 0; i < 12; i++) begin : _0
            assign CMPy[i] = (((ShQueueCAM1[i] == eu0_wk) & eu0_vld) | ((ShQueueCAM1[i] == eu1_wk) & eu1_vld) | ((ShQueueCAM1[i] == eu2_wk) & eu2_vld)) & vld[i];
        end
    endgenerate

    generate
        for (genvar i = 0; i < 12; i++) begin : _1
            assign AV2l[i] = (AV2[i] | CMPy[i]) & !flush_i;
        end
    endgenerate
    generate
        for (genvar i = 0; i < 12; i++) begin : _9
            assign AV1l[i] = (AV1[i] | CMPs[i]) & !flush_i;
        end
    endgenerate
    generate 
        for (genvar i = 0; i < 12; i++) begin : _______
            assign CMPs[i] = (((ShQueueCAM0[i] == eu0_wk) & eu0_vld) | ((ShQueueCAM0[i] == eu1_wk) & eu1_vld) | ((ShQueueCAM0[i] == eu2_wk) & eu2_vld) )& vld[i];
        end
    endgenerate
    generate
        for (genvar i = 0; i < 12; i++) begin : _2
            assign vldl[i] = vld[i] & !ddec[i] & !ddec2[i] & !flush_i;
        end
    endgenerate
    generate
        for (genvar i = 0; i < 12; i++) begin: _3
            assign data_rdy[i] = vld[i] & AV2[i] & AV1[i] & !flush_i;
        end
    endgenerate
    generate 
        for (genvar i = 0; i < 10; i++) begin : _4
            always_ff @(posedge cpu_clk_i) begin
                vld[i] <= shift_two[i] ? vldl[i+2] : shift[i] ? vldl[i+1] : vldl[i];
            end
        end
    endgenerate
    generate 
        for (genvar i = 0; i < 10; i++) begin : _5
            always_ff @(posedge cpu_clk_i) begin
                AV2[i] <= shift_two[i] ? AV2l[i+2] : shift[i] ? AV2l[i+1] : AV2l[i];
            end
        end
    endgenerate
    generate 
        for (genvar i = 0; i < 10; i++) begin : _13
            always_ff @(posedge cpu_clk_i) begin
                branch[i] <= shift_two[i] ? branch[i+2] : shift[i] ? branch[i+1] : branch[i];
            end
        end
    endgenerate
    generate 
        for (genvar i = 0; i < 10; i++) begin : _10
            always_ff @(posedge cpu_clk_i) begin
                AV1[i] <= shift_two[i] ? AV1l[i+2] : shift[i] ? AV1l[i+1] : AV1l[i];
            end
        end
    endgenerate
    generate 
        for (genvar i = 0; i < 10; i++) begin : _6
            always_ff @(posedge cpu_clk_i) begin
                ShQueueRAM[i] <= shift_two[i] ? ShQueueRAM[i+2] : shift[i] ? ShQueueRAM[i+1] : ShQueueRAM[i];
            end
        end
    endgenerate
    generate 
        for (genvar i = 0; i < 10; i++) begin : _7
            always_ff @(posedge cpu_clk_i) begin
                ShQueueCAM1[i] <= shift_two[i] ? ShQueueCAM1[i+2] : shift[i] ? ShQueueCAM1[i+1] : ShQueueCAM1[i];
            end
        end
    endgenerate
        generate 
        for (genvar i = 0; i < 10; i++) begin : _11
            always_ff @(posedge cpu_clk_i) begin
                ShQueueCAM0[i] <= shift_two[i] ? ShQueueCAM0[i+2] : shift[i] ? ShQueueCAM0[i+1] : ShQueueCAM0[i];
            end
        end
    endgenerate
    wire p0_av1_temp;
    assign p0_av1_temp = ((((p0_data_i[17:12] == eu0_wk) & eu0_vld) | ((p0_data_i[17:12] == eu1_wk) & eu1_vld) | ((p0_data_i[17:12] == eu2_wk) & eu2_vld)))|p0_rs1_rdy|!p0_rs1_vld_i;
    wire p1_av1_temp;
    assign p1_av1_temp = ((((p1_data_i[17:12] == eu0_wk) & eu0_vld) | ((p1_data_i[17:12] == eu1_wk) & eu1_vld) | ((p1_data_i[17:12] == eu2_wk) & eu2_vld)))|p1_rs1_rdy|!p1_rs1_vld_i;

    wire p0_av2_temp;
    assign p0_av2_temp = (((p0_data_i[11:6] == eu0_wk) & eu0_vld) | ((p0_data_i[11:6] == eu1_wk) & eu1_vld) | ((p0_data_i[11:6] == eu2_wk) & eu2_vld) )|p0_rs2_rdy||!p0_rs2_vld_i;
    wire p1_av2_temp;
    assign p1_av2_temp = ((((p1_data_i[11:6] == eu0_wk)& eu0_vld) | ((p1_data_i[11:6] == eu1_wk) & eu1_vld) | ((p1_data_i[11:6] == eu2_wk) & eu2_vld) ))|p1_rs2_rdy|!p1_rs2_vld_i;

    always_ff @(posedge cpu_clk_i) begin
        ShQueueCAM1[11] <= shift_two[11] ? p1_data_i[11:6] : shift[11] ? p0_data_i[11:6] : ShQueueCAM1[11];
        ShQueueCAM1[10] <= shift_two[10] ? p0_data_i[11:6] : shift[10] ? ShQueueCAM1[11] : ShQueueCAM1[10];
        ShQueueCAM0[11] <= shift_two[11] ? p1_data_i[17:12] : shift[11] ? p0_data_i[17:12] : ShQueueCAM0[11];
        ShQueueCAM0[10] <= shift_two[10] ? p0_data_i[17:12] : shift[10] ? ShQueueCAM0[11] : ShQueueCAM0[10];
        ShQueueRAM[11] <= shift_two[11] ? p1_data_i[5:0] : shift[11] ? p0_data_i[5:0] : ShQueueRAM[11];
        ShQueueRAM[10] <= shift_two[10] ? p0_data_i[5:0] : shift[10] ? ShQueueRAM[11] : ShQueueRAM[10];

        vld[11] <= shift_two[11] ? p1_vld_i&!flush_i : shift[11] ? p0_vld_i&!flush_i : vldl[11];
        vld[10] <= shift_two[10] ? p0_vld_i&!flush_i : shift[10] ? vldl[11] : vldl[10];
        branch[11] <= shift_two[11] ? p1_data_i[18] : shift[11] ? p0_data_i[18] : branch[11];
        branch[10] <= shift_two[10] ? p0_data_i[18] : shift[10] ? branch[11] : branch[10];
        AV2[11] <= shift_two[11] ? p1_av2_temp&!flush_i&p1_vld_i : shift[11] ? p0_av2_temp&!flush_i&p0_vld_i : AV2l[11];
        AV2[10] <= shift_two[10] ? p0_av2_temp&!flush_i&p0_vld_i : shift[10] ? AV2l[11] : AV2l[10];
        AV1[11] <= shift_two[11] ? p1_av1_temp&!flush_i&p1_vld_i : shift[11] ? p0_av1_temp&!flush_i&p0_vld_i : AV1l[11];
        AV1[10] <= shift_two[10] ? p0_av1_temp&!flush_i&p0_vld_i : shift[10] ? AV1l[11] : AV1l[10];
    end
    logic [5:0] rs1;
    logic [5:0] rs2;
    logic [5:0] rob;
    wire [11:0] initial_ready = data_rdy&~branch;
    always_comb begin
        casez (initial_ready)
            12'bzzzzzzzzzzz1: begin
                ddec = 12'b000000000001;
                rs1 = ShQueueCAM0[0];
                rs2 = ShQueueCAM1[0];
                rob = ShQueueRAM[0];
            end
            12'bzzzzzzzzzz10: begin
                ddec = 12'b000000000010;
                rs1 = ShQueueCAM0[1];
                rs2 = ShQueueCAM1[1];
                rob = ShQueueRAM[1];
            end
            12'bzzzzzzzzz100: begin
                ddec = 12'b000000000100;
                rs1 = ShQueueCAM0[2];
                rs2 = ShQueueCAM1[2];
                rob = ShQueueRAM[2];
            end
            12'bzzzzzzzz1000: begin
                ddec = 12'b000000001000;
                rs1 = ShQueueCAM0[3];
                rs2 = ShQueueCAM1[3];
                rob = ShQueueRAM[3];
            end
            12'bzzzzzzz10000: begin
                ddec = 12'b000000010000;
                rs1 = ShQueueCAM0[4];
                rs2 = ShQueueCAM1[4];
                rob = ShQueueRAM[4];
            end            
            12'bzzzzzz100000: begin
                ddec = 12'b000000100000;
                rs1 = ShQueueCAM0[5];
                rs2 = ShQueueCAM1[5];
                rob = ShQueueRAM[5];
            end     
            12'bzzzzz1000000: begin
                ddec = 12'b000001000000;
                rs1 = ShQueueCAM0[6];
                rs2 = ShQueueCAM1[6];
                rob = ShQueueRAM[6];
            end   
            12'bzzzz10000000: begin
                ddec = 12'b000010000000;
                rs1 = ShQueueCAM0[7];
                rs2 = ShQueueCAM1[7];
                rob = ShQueueRAM[7];
            end      
            12'bzzz100000000: begin
                ddec = 12'b000100000000;
                rs1 = ShQueueCAM0[8];
                rs2 = ShQueueCAM1[8];
                rob = ShQueueRAM[8];
            end    
            12'bzz1000000000: begin
                ddec = 12'b001000000000;
                rs1 = ShQueueCAM0[9];
                rs2 = ShQueueCAM1[9];
                rob = ShQueueRAM[9];
            end    
            12'bz10000000000: begin
                ddec = 12'b010000000000;
                rs1 = ShQueueCAM0[10];
                rs2 = ShQueueCAM1[10];
                rob = ShQueueRAM[10];
            end    
            12'b100000000000: begin
                ddec = 12'b100000000000;
                rs1 = ShQueueCAM0[11];
                rs2 = ShQueueCAM1[11];
                rob = ShQueueRAM[11];
            end    
            default: begin
                ddec = 12'h000;
                rs1 = ShQueueCAM0[0];
                rs2 = ShQueueCAM1[0];
                rob = ShQueueRAM[0];
            end
        endcase
    end
    wire [11:0] second_ready = data_rdy&~ddec;
    logic [5:0] rs12;
    logic [5:0] rs22;
    logic [5:0] rob2;
    always_comb begin
        casez (second_ready)
            12'bzzzzzzzzzzz1: begin
                ddec2 = 12'b000000000001;
                rs12 = ShQueueCAM0[0];
                rs22 = ShQueueCAM1[0];
                rob2 = ShQueueRAM[0];
            end
            12'bzzzzzzzzzz10: begin
                ddec2 = 12'b000000000010;
                rs12 = ShQueueCAM0[1];
                rs22 = ShQueueCAM1[1];
                rob2 = ShQueueRAM[1];
            end
            12'bzzzzzzzzz100: begin
                ddec2 = 12'b000000000100;
                rs12 = ShQueueCAM0[2];
                rs22 = ShQueueCAM1[2];
                rob2 = ShQueueRAM[2];
            end
            12'bzzzzzzzz1000: begin
                ddec2 = 12'b000000001000;
                rs12 = ShQueueCAM0[3];
                rs22 = ShQueueCAM1[3];
                rob2 = ShQueueRAM[3];
            end
            12'bzzzzzzz10000: begin
                ddec2 = 12'b000000010000;
                rs12 = ShQueueCAM0[4];
                rs22 = ShQueueCAM1[4];
                rob2 = ShQueueRAM[4];
            end            
            12'bzzzzzz100000: begin
                ddec2 = 12'b000000100000;
                rs12 = ShQueueCAM0[5];
                rs22 = ShQueueCAM1[5];
                rob2 = ShQueueRAM[5];
            end     
            12'bzzzzz1000000: begin
                ddec2 = 12'b000001000000;
                rs12 = ShQueueCAM0[6];
                rs22 = ShQueueCAM1[6];
                rob2 = ShQueueRAM[6];
            end   
            12'bzzzz10000000: begin
                ddec2 = 12'b000010000000;
                rs12 = ShQueueCAM0[7];
                rs22 = ShQueueCAM1[7];
                rob2 = ShQueueRAM[7];
            end      
            12'bzzz100000000: begin
                ddec2 = 12'b000100000000;
                rs12 = ShQueueCAM0[8];
                rs22 = ShQueueCAM1[8];
                rob2 = ShQueueRAM[8];
            end    
            12'bzz1000000000: begin
                ddec2 = 12'b001000000000;
                rs12 = ShQueueCAM0[9];
                rs22 = ShQueueCAM1[9];
                rob2 = ShQueueRAM[9];
            end    
            12'bz10000000000: begin
                ddec2 = 12'b010000000000;
                rs12 = ShQueueCAM0[10];
                rs22 = ShQueueCAM1[10];
                rob2 = ShQueueRAM[10];
            end    
            12'b100000000000: begin
                ddec2 = 12'b100000000000;
                rs12 = ShQueueCAM0[11];
                rs22 = ShQueueCAM1[11];
                rob2 = ShQueueRAM[11];
            end    
            default: begin
                ddec2 = 12'h000;
                rs12 = ShQueueCAM0[0];
                rs22 = ShQueueCAM1[0];
                rob2 = ShQueueRAM[0];
            end
        endcase
    end
    initial alu_vld_o = 0; initial alu2_vld_o = 0;
    always_ff @(posedge cpu_clk_i) begin
        if ((|second_ready)& ~flush_i) begin
            alu_data_o <= {rs22, rs12, rob2};
            alu_vld_o <= 1'b1;
        end
        else begin
            alu_vld_o <= 1'b0;
        end
        if ((|initial_ready)& ~flush_i) begin
            alu2_data_o <= {rs2, rs1, rob};
            alu2_vld_o <= 1'b1;
        end
        else begin
            alu2_vld_o <= 1'b0;
        end
    end
endmodule
