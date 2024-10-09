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
module op_dec #(parameter ENABLE_M_EXTENSION = 1) (
    input   wire logic [6:0]    func7,
    input   wire logic [2:0]    func3,

    output  wire logic [6:0]    uop,
    output  wire logic          port,
    output  wire logic          valid
);
    // 35 LUTs in vivado using synthesis defaults
    // All single cycle OPs
    localparam RV_ADD = 7'b0000000;
    localparam RV_SH1ADD = 7'b0000001;
    localparam RV_SH2ADD = 7'b0000010;
    localparam RV_SH3ADD = 7'b0000011;
    localparam RV_SUB = 7'b0000100;
    localparam RV_ZEXT_H = 7'b0001010;
    localparam RV_SLL = 7'b0100000;
    localparam RV_SLR = 7'b0100001;
    localparam RV_ROL = 7'b0100010;
    localparam RV_ROR = 7'b0100011;
    localparam RV_SRA = 7'b0100101;
    localparam RV_BCLR = 7'b0101000;
    localparam RV_BEXT = 7'b0101011;
    localparam RV_BINV = 7'b0111000;
    localparam RV_BSET = 7'b0111010;
    localparam RV_MAXU = 7'b1000000;
    localparam RV_MINU = 7'b1000001;
    localparam RV_SLT = 7'b1000010;
    localparam RV_SLTU = 7'b1000011;
    localparam RV_MAX = 7'b1000100;
    localparam RV_MIN = 7'b1000101; 
    localparam RV_CZEROEQZ = 7'b1000110;
    localparam RV_CZERONEZ = 7'b1000111;
    localparam RV_AND = 7'b1100000;
    localparam RV_ORR = 7'b1100001;
    localparam RV_XOR = 7'b1100010;
    localparam RV_ANDN = 7'b1100100;
    localparam RV_ORN = 7'b1100101;
    localparam RV_XNOR = 7'b1100110;
    localparam RV_MUL = 7'b0000000;
    localparam RV_MULH = 7'b0000001;
    localparam RV_MULHSU = 7'b0000010;
    localparam RV_MULHU = 7'b0000011;
    localparam RV_DIV = 7'b0000100;
    localparam RV_DIVU = 7'b0000101;
    localparam RV_REM = 7'b0000110;
    localparam RV_REMU = 7'b0000111;
    
    // case 000
    wire [6:0] case_000_instruction;
    generate if (ENABLE_M_EXTENSION) begin : hndl_case_0
        assign case_000_instruction = func7==7'b0000000 ? RV_ADD : func7==7'b0100000 ? RV_SUB : RV_MUL;
    end
    else begin : hndl_case_0_woM
        assign case_000_instruction = func7==7'b0000000 ? RV_ADD : RV_SUB;
    end endgenerate
    wire case_000_valid = (func7==7'b0000000)|(func7==7'b0100000)|((func7==7'b0000001)&ENABLE_M_EXTENSION);

    wire [6:0] case_001_instruction;
    generate if (ENABLE_M_EXTENSION) begin : hndl_case_1
        assign case_001_instruction = func7==7'b0000000 ? RV_SLL : func7==7'b0010100 ? RV_BSET : func7==7'b0100100 ? RV_BCLR : 
        func7 == 7'b0110100 ? RV_BINV : func7 == 7'b0110000 ? RV_ROL : RV_MULH;
    end
    else begin : hndl_case_1_woM
        assign case_001_instruction = func7==7'b0000000 ? RV_SLL : func7==7'b0010100 ? RV_BSET : func7==7'b0100100 ? RV_BCLR : 
        func7 == 7'b0110100 ? RV_BINV : RV_ROL;
    end endgenerate
    wire case_001_valid = (func7==7'b0000000)|(func7==7'b0010100)|(func7==7'b0100100)|
    (func7==7'b0110100)|(func7==7'b0110000)|((func7==7'b0000001)&ENABLE_M_EXTENSION);

    wire [6:0] case_010_instruction;
    generate if (ENABLE_M_EXTENSION) begin : hndl_case_2
        assign case_010_instruction = func7==7'b0000000 ? RV_SLT : func7==7'b0010000 ? RV_SH1ADD : RV_MULHSU; 
    end else begin : hndl_case_2_woM
        assign case_010_instruction = func7==7'b0000000 ? RV_SLT : RV_SH1ADD; 
    end
    endgenerate
    wire case_010_valid = (func7==7'b0000000)|(func7==7'b0010000)|((func7==7'b0000001)&ENABLE_M_EXTENSION);

    wire [6:0] case_011_instruction;
    generate if (ENABLE_M_EXTENSION) begin : hndl_case_3
        assign case_011_instruction = func7==7'b0000000 ? RV_SLTU : RV_MULHU;
    end else begin : hndl_case_3_woM
        assign case_011_instruction = RV_SLTU;
    end
    endgenerate
    wire case_011_valid = (func7==7'b0000000)|((func7==7'b0000001)&ENABLE_M_EXTENSION);

    wire [6:0] case_100_instruction;
    generate if (ENABLE_M_EXTENSION) begin : hndl_case_4
        assign case_100_instruction = func7==7'b0000000 ? RV_XOR : func7 == 7'b0000100 ? RV_ZEXT_H : func7==7'b0100000 ? RV_XNOR : 
        func7==7'b0000101 ? RV_MIN : func7==7'b0010000 ? RV_SH2ADD : RV_DIV;
    end else begin : hndl_case_4_woM
        assign case_100_instruction = func7==7'b0000000 ? RV_XOR : func7 == 7'b0000100 ? RV_ZEXT_H : func7==7'b0100000 ? RV_XNOR : 
        func7==7'b0000101 ? RV_MIN : RV_SH2ADD;
    end
    endgenerate    
    wire case_100_valid = (func7==7'b0000000)|(func7 == 7'b0000100)|(func7==7'b0100000)|(func7==7'b0000101)|(func7==7'b0010000)|((func7==7'b0000001)&ENABLE_M_EXTENSION);

    wire [6:0] case_101_instruction;
    generate if (ENABLE_M_EXTENSION) begin : hndl_case_5
        assign case_101_instruction = func7==7'b0000000 ? RV_SLR : func7==7'b0100000 ? RV_SRA : func7==7'b0100100 ? RV_BEXT : func7==7'b0000101 ? RV_MINU :
        func7==7'b0110000 ? RV_ROR : func7==7'b0000111 ? RV_CZEROEQZ : RV_DIVU;
    end else begin : hndl_case_5_woM
        assign case_101_instruction = func7==7'b0000000 ? RV_SLR : func7==7'b0100000 ? RV_SRA : func7==7'b0100100 ? RV_BEXT : func7==7'b0000101 ? RV_MINU :
        func7==7'b0110000 ? RV_ROR : RV_CZEROEQZ;
    end
    endgenerate
    wire case_101_valid = (func7==7'b0000000)|(func7==7'b0100000)|(func7==7'b0100100)|(func7==7'b0000101)|(func7==7'b0110000)|(func7==7'b0000111)|
    ((func7==7'b0000001)&ENABLE_M_EXTENSION);

    wire [6:0] case_110_instruction;
    generate if (ENABLE_M_EXTENSION) begin : hndl_case_6
        assign case_110_instruction = func7==7'b0000000 ? RV_ORR : func7 == 7'b0000101 ? RV_MAX : func7==7'b0100000 ? RV_ORN : func7==7'b0010000 ? RV_SH3ADD : RV_REM;
    end else begin : hndl_case_6_woM
        assign case_110_instruction = func7==7'b0000000 ? RV_ORR : func7 == 7'b0000101 ? RV_MAX : func7==7'b0100000 ? RV_ORN : RV_SH3ADD;
    end
    endgenerate
    wire case_110_valid = (func7==7'b0000000)|(func7 == 7'b0000101)|(func7==7'b0100000)|(func7==7'b0010000)|((func7==7'b0000001)&ENABLE_M_EXTENSION);

    wire [6:0] case_111_instruction;
    generate if (ENABLE_M_EXTENSION) begin : hndl_case_7
        assign case_111_instruction = func7==7'b0000000 ? RV_AND : func7==7'b0100000 ? RV_ANDN : func7==7'b0000101 ? RV_MAXU : (func7==7'b0000111) ? RV_CZERONEZ : RV_REMU;
    end else begin : hndl_case_7_woM
        assign case_111_instruction = func7==7'b0000000 ? RV_AND : func7==7'b0100000 ? RV_ANDN : (func7==7'b0000111) ? RV_CZERONEZ : RV_MAXU;
    end
    endgenerate
    wire case_111_valid = (func7==7'b0000000)|(func7 == 7'b0000101)|(func7==7'b0100000)|((func7==7'b0000001)&ENABLE_M_EXTENSION)|(func7==7'b0000111);

    assign valid = func3==3'b000 ? case_000_valid :
                   func3==3'b001 ? case_001_valid :
                   func3==3'b010 ? case_010_valid :
                   func3==3'b011 ? case_011_valid :
                   func3==3'b100 ? case_100_valid :
                   func3==3'b101 ? case_101_valid : 
                   func3==3'b110 ? case_110_valid : 
                   case_111_valid;
    assign uop  =  func3==3'b000 ? case_000_instruction :
                   func3==3'b001 ? case_001_instruction :
                   func3==3'b010 ? case_010_instruction :
                   func3==3'b011 ? case_011_instruction :
                   func3==3'b100 ? case_100_instruction :
                   func3==3'b101 ? case_101_instruction : 
                   func3==3'b110 ? case_110_instruction : 
                   case_111_instruction;
    assign port = (func7==7'b0000001)&ENABLE_M_EXTENSION;

endmodule
