module meu_lsu #(
    parameter C_NUM_OF_REGIONS = 2,
    parameter [C_NUM_OF_REGIONS*32-1:0] C_BASE_ADDRESSES = {32'h00000000, 32'h80000000},
    parameter [C_NUM_OF_REGIONS*32-1:0] C_ADDRESS_MASKS = {32'h00000000, 32'h80000000},
    parameter [C_NUM_OF_REGIONS-1:0] C_MEMORY_ATTRIBUTES = {1'b0, 1'b1}
) (
    // CPU <-> Cache System entry
    output wire        lsu_busy_o,
    input  wire        lsu_vld_i,
    input  wire [ 5:0] lsu_rob_i,
    input  wire [ 1:0] lsu_sz_i,
    input  wire [ 2:0] lsu_op_i,
    input  wire [ 4:0] lsu_param_i,
    input  wire [31:0] lsu_addr_i,
    input  wire [31:0] lsu_data_i,
    input  wire [ 5:0] lsu_dest_i,
    input  wire [31:0] lsu_algn_dat_i,
    input  wire [ 3:0] lsu_bitmask_i,
    // Cache System <-> Store Queue Module (**ALL** regular stores go here)
    input  wire        sq_full_i,
    output wire [29:0] sq_address_o,
    output wire [31:0] sq_data_o,
    output wire [ 3:0] sq_bm_o,
    output wire        sq_io_o,
    output wire        sq_en_o,
    output wire [ 4:0] sq_rob_o,
    // Cache System <-> Load Path Module
    input  wire        ld_busy_i,
    output wire        ld_vld_o,
    output wire [ 5:0] ld_rob_o,
    output wire [ 1:0] ld_sz_o,
    output wire [ 2:0] ld_op_o,
    output wire [ 4:0] ld_param_o,
    output wire [31:0] ld_addr_o,
    output wire [31:0] ld_data_o,
    output wire [ 5:0] ld_dest_o,
    output wire [ 3:0] ld_bitmask_o,
    output wire        ld_kill_o,
    // Cache System <-> PMA (may need moving)
    output wire [24:0] d_addr,
    output wire        d_write,
    input  wire        d_kill,
    // Cache System <-> PMC
    output wire [31:0] excp_pc,
    output wire        excp_valid,
    output wire [ 3:0] excp_code_o,
    output wire [ 5:0] excp_rob
);
  wire io;
  wire region_valid;
  pma #(
      .C_NUM_OF_REGIONS(C_NUM_OF_REGIONS),
      .C_BASE_ADDRESSES(C_BASE_ADDRESSES),
      .C_ADDRESS_MASKS(C_ADDRESS_MASKS),
      .C_MEMORY_ATTRIBUTES(C_MEMORY_ATTRIBUTES)
  ) pma_inst (
      .address(lsu_addr_i),
      .peripheral(io),
      .valid(region_valid)
  );

  assign lsu_busy_o = sq_full_i || ld_busy_i;
  assign d_addr = lsu_addr_i[31:7];
  assign d_write = lsu_op_i == 3'd1 || lsu_op_i == 3'd2 || lsu_op_i == 3'd4;
  assign sq_address_o = lsu_addr_i[31:2];
  assign sq_data_o = lsu_algn_dat_i;
  assign sq_bm_o = lsu_bitmask_i;
  assign sq_en_o = lsu_op_i == 3'd1 && lsu_vld_i && !d_kill && region_valid && (lsu_bitmask_i==4'b0110);
  assign sq_rob_o = lsu_rob_i[4:0];
  assign sq_io_o = io;
  assign ld_kill_o = d_kill || !region_valid;
  assign ld_vld_o = lsu_vld_i;
  assign ld_rob_o = lsu_rob_i;
  assign ld_sz_o = lsu_sz_i;
  assign ld_op_o = lsu_op_i;
  assign ld_param_o = lsu_param_i;
  assign ld_addr_o = lsu_addr_i;
  assign ld_data_o = lsu_data_i;
  assign ld_dest_o = lsu_dest_i;
  assign ld_bitmask_o = lsu_bitmask_i;


  assign excp_code_o = d_kill ? lsu_op_i != 3'd0 && lsu_op_i!=3'd3 ? 4'd7 : 4'd5 : isWrite ? 4'd6 : 4'd4;
endmodule
