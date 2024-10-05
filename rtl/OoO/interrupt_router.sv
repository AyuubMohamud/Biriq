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
module interrupt_router (
    input   wire logic              current_privilege_mode,
    input   wire logic              mie,
    input   wire logic [2:0]        machine_interrupts,

    output  wire logic              int_o,
    output  wire logic [3:0]        int_type
);
    
    wire go_to_M = (((current_privilege_mode)&&mie)||(!current_privilege_mode)) && ((|machine_interrupts));

    wire [3:0] enc_M_only = machine_interrupts[2] ? 4'd11 :
                            machine_interrupts[0] ? 4'd3 :
                            4'd7;

    assign int_o = go_to_M;
    assign int_type = enc_M_only;
endmodule
