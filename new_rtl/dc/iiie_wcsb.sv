module iiie_wcsb #(
    parameter C_WCSB_ENTRIES = 0
) (
    input wire clock,
    input wire reset,
    input wire [29:0] enqueue_addr,
    input wire [31:0] enqueue_data,
    input wire [3:0] enqueue_mask,
    input wire enqueue_en,
    output wire enqueue_stall,
    output logic [28:0] out_cache_addr,
    output logic [63:0] out_cache_data,
    output logic [7:0] out_cache_mask,
    output logic out_cache_valid,
    input wire in_cache_ready
);
  localparam ent = C_WCSB_ENTRIES;
  reg [   28:0] wcsb_addr  [0:ent-1];
  reg [   63:0] wcsb_data  [0:ent-1];
  reg [    7:0] wcsb_mask  [0:ent-1];
  reg [ent-1:0] wcsb_valid;



endmodule
