module map (
    input wire clock,
    input wire flush,
    input wire [4:0] ins0_dest_i,
    input wire ins0_valid,
    input wire [4:0] ins1_dest_i,
    input wire ins1_valid,
    input wire [4:0] ins0_rs1_i,
    input wire [4:0] ins0_rs2_i,
    input wire [4:0] ins1_rs1_i,
    input wire [4:0] ins1_rs2_i,
    output wire ins0_rs1_commit_o,
    output wire ins0_rs2_commit_o,
    output wire ins1_rs1_commit_o,
    output wire ins1_rs2_commit_o,
    output wire ins0_dest_commit_o,
    output wire ins1_dest_commit_o
);
  reg [31:0] map_ff;
  initial map_ff = '1;
  for (genvar k = 1; k < 32; k++) begin : g_map
    always @(posedge clock) begin
      map_ff[k] <= flush ? 1'b1 : (ins0_dest_i==k && ins0_valid)||(ins1_dest_i==k && ins1_valid) ? 1'b0 : map_ff[k];
    end
  end
  assign ins0_rs1_commit_o  = map_ff[ins0_rs1_i];
  assign ins0_rs2_commit_o  = map_ff[ins0_rs2_i];
  assign ins1_rs1_commit_o  = map_ff[ins1_rs1_i] && !(ins0_dest_i == ins1_rs1_i && ins0_valid);
  assign ins1_rs2_commit_o  = map_ff[ins1_rs2_i] && !(ins0_dest_i == ins1_rs2_i && ins0_valid);
  assign ins0_dest_commit_o = map_ff[ins0_dest_i];
  assign ins1_dest_commit_o = map_ff[ins1_dest_i];
endmodule
