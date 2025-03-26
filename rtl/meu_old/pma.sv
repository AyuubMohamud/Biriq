module pma #(
    parameter C_NUM_OF_REGIONS = 2,
    parameter [C_NUM_OF_REGIONS*32-1:0] C_BASE_ADDRESSES = {32'h00000000, 32'h80000000},
    parameter [C_NUM_OF_REGIONS*32-1:0] C_ADDRESS_MASKS = {32'h00000000, 32'h80000000},
    parameter [C_NUM_OF_REGIONS-1:0] C_MEMORY_ATTRIBUTES = {1'b0, 1'b1}
) (
    input  wire  [31:0] address,
    output logic        peripheral,
    output logic        valid
);
  genvar i;
  logic [C_NUM_OF_REGIONS-1:0] range_decode;
  for (i = 0; i < C_NUM_OF_REGIONS; i++) begin
    always_comb
      range_decode[i] = (address & C_ADDRESS_MASKS[32*(i+1)-1:32*i]) == C_BASE_ADDRESSES[32*(i+1)-1:32*i];
  end
  always_comb begin
    peripheral = '0;
    valid = |range_decode;
    for (integer k = 0; k < C_NUM_OF_REGIONS; k++) begin
      if (range_decode[k]) peripheral = C_MEMORY_ATTRIBUTES[k];
    end
  end
endmodule
