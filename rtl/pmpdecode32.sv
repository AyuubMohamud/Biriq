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
module pmpdecode32 (
    input   wire logic [29:0] address,
    output       logic [29:0] mask,
    output       logic [29:0] match_address
);
    logic finishs;
    logic finishs2;
    always_comb begin
        mask = '1;
        match_address = address;
        finishs = '0;
        finishs2 = '0;
        for (integer i = 0; i < 30; i++) begin
            if (!finishs&address[i]) begin
                mask[i] = 0;
                finishs = 1;
            end
        end
        for (integer i = 0; i < 30; i++) begin
            if (!finishs2&address[i]) begin
                match_address[i] = 0;
                finishs2 = 1;
            end
        end
    end

endmodule
