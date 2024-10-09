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
module genOneHot #(parameter WIDTH = 10) (
    input wire [WIDTH-1:0] bitvec,
    output logic onehot
);

    logic dectected_one;
    logic more_than_one;
    logic FINISHSEL;
    logic FINISHSEL2;
    logic [$clog2(WIDTH)-1:0] scan;
    always_comb begin
        dectected_one = '0;
        FINISHSEL = '0;
        scan = 0;
        for (integer i = 0; i < WIDTH; i++) begin
            if (bitvec[i]&!FINISHSEL) begin
                dectected_one = 1;
                FINISHSEL = 1;
                scan = i[$clog2(WIDTH)-1:0];
            end
        end
    end
    always_comb begin
        more_than_one = '0;
        FINISHSEL2 = '0;
        for (integer i = 0; i < WIDTH; i++) begin
            if (bitvec[i]&(i[$clog2(WIDTH)-1:0]!=scan)&&dectected_one&&!FINISHSEL2) begin
                more_than_one = 1;
                FINISHSEL2 = 1;
            end
        end
    end
    assign onehot = dectected_one&!more_than_one;
endmodule
