module binfo (
    input   wire logic                  cpu_clock_i,

    input   wire logic [29:0]           rn_pc_i,
    input   wire logic  [1:0]           rn_bm_pred_i,
    input   wire logic  [1:0]           rn_btype_i,
    input   wire logic                  rn_btb_vld_i,
    input   wire logic  [29:0]          rn_btb_target_i,
    input   wire logic                  rn_btb_way_i,
    input   wire logic                  rn_btb_idx_i,
    input   wire logic [3:0]            rn_btb_pack,
    input   wire logic                  rn_btb_wen,

    input   wire logic [3:0]            pack_i,
    output  wire logic [29:0]           pc_o,
    output  wire logic  [1:0]           bm_pred_o,
    output  wire logic  [1:0]           btype_o,
    output  wire logic                  btb_vld_o,
    output  wire logic  [29:0]          btb_target_o,
    output  wire logic                  btb_way_o,
    output  wire logic                  btb_idx_o
);
    reg [66:0] binfo_ram [0:15];

    always_ff @(posedge cpu_clock_i) begin
        if (rn_btb_wen) begin
            binfo_ram[rn_btb_pack] <= {rn_pc_i,
            rn_bm_pred_i,
            rn_btype_i,
            rn_btb_vld_i,
            rn_btb_target_i,
            rn_btb_way_i,
            rn_btb_idx_i};
        end
    end
    assign {pc_o,
    bm_pred_o,
    btype_o,
    btb_vld_o,
    btb_target_o,
    btb_way_o,
    btb_idx_o} = binfo_ram[pack_i];
endmodule
