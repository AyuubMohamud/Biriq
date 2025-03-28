module mem_rr (
    input wire logic core_clock_i,
    input wire logic core_flush_i,

    output wire        meu_busy_o,
    input  wire        meu_vld_i,
    input  wire [ 5:0] meu_rob_i,
    input  wire [ 5:0] meu_type_i,
    input  wire [ 2:0] meu_op_i,
    input  wire [31:0] meu_imm_i,
    input  wire [ 5:0] meu_rs1_i,
    input  wire [ 5:0] meu_rs2_i,
    input  wire [ 5:0] meu_dest_i,

    // prf
    input  wire [31:0] rs1_data,
    output wire [ 5:0] rs1_o,
    input  wire [31:0] rs2_data,
    output wire [ 5:0] rs2_o,

    input  wire         agu_busy_i,
    output logic        agu_vld_o,
    output logic [ 5:0] agu_rob_o,
    output logic        agu_cmo_o,
    output logic [ 3:0] agu_op_o,
    output logic [31:0] agu_rs1_o,
    output logic [31:0] agu_rs2_o,
    output logic [31:0] agu_imm_o,
    output logic [ 5:0] agu_dest_o,

    // csrfile inputs
    output logic [31:0] tmu_data_o,
    output logic [11:0] tmu_address_o,
    output logic [ 1:0] tmu_opcode_o,
    output logic        tmu_wr_en,
    output logic        tmu_valid_o,
    input  wire         tmu_done_i,
    input  wire         tmu_excp_i,
    input  wire  [31:0] tmu_data_i,
    input  wire         store_buffer_empty,
    input  wire         rob_lock,
    input  wire  [ 4:0] rob_oldest_i,
    output wire  [ 4:0] completed_rob_id,
    output wire         completion_valid,
    output wire         exception_o,
    output wire  [ 5:0] exception_rob_o,
    output wire  [ 3:0] exception_code_o,
    output wire         p2_we_i,
    output wire  [31:0] p2_we_data,
    output wire  [ 5:0] p2_we_dest
);
  wire performing_system_operation = |meu_type_i[2:1];
  wire system_instruction_done;
  assign meu_busy_o = agu_busy_i | (!system_instruction_done & performing_system_operation & meu_vld_i);
  reg csrfile_being_read;
  reg fence_exec;
  initial csrfile_being_read = 1'b0;
  initial fence_exec = 1'b0;
  wire can_commit_non_specs = (meu_rob_i[4:0] == rob_oldest_i) && !rob_lock;
  always_ff @(posedge core_clock_i) begin
    if (core_flush_i) begin
      agu_vld_o <= 0;
    end else if ((|meu_type_i[4:3]) & !agu_busy_i & meu_vld_i) begin
      agu_rs1_o  <= rs1_data;
      agu_rs2_o  <= rs2_data;
      agu_dest_o <= meu_dest_i;
      agu_rob_o  <= meu_rob_i;
      agu_op_o   <= {meu_type_i[3], meu_op_i};
      agu_imm_o  <= meu_imm_i;
      agu_vld_o  <= 1;
      agu_cmo_o  <= 0;
    end else if (!agu_busy_i & (meu_type_i[5]) & meu_vld_i) begin
      agu_rs1_o  <= rs1_data;
      agu_dest_o <= meu_dest_i;
      agu_rob_o  <= meu_rob_i;
      agu_op_o   <= {1'b0, meu_op_i};
      agu_imm_o  <= '0;
      agu_vld_o  <= 1;
      agu_cmo_o  <= 1;
    end else if (!agu_busy_i) begin
      agu_vld_o <= 0;
    end
  end

  assign system_instruction_done = (csrfile_being_read&tmu_done_i) ||
  ((store_buffer_empty)&&fence_exec);
  // system instructions require a flush sometimes
  always_ff @(posedge core_clock_i) begin : csrfile_modifications
    if (tmu_done_i) begin
      csrfile_being_read <= 0;
    end
      else if (((can_commit_non_specs&performing_system_operation&&(meu_type_i[2])))&!tmu_valid_o& meu_vld_i) begin
      csrfile_being_read <= 1'b1;
      tmu_opcode_o <= meu_op_i[1:0];
      tmu_data_o <= meu_op_i[2] ? {27'h0, meu_rs1_i[4:0]} : meu_op_i[1] ? {27'h0, rs1_data[4:0]} : rs1_data;
      tmu_address_o <= meu_imm_i[11:0];
      tmu_wr_en <= (meu_rs1_i != 0 | meu_op_i[2]);
      tmu_valid_o <= 1;
    end else if (tmu_valid_o) begin
      tmu_valid_o <= 0;
    end
  end

  always_ff @(posedge core_clock_i) begin : fence_logic
    if (fence_exec) begin
      if ((store_buffer_empty)) begin
        fence_exec <= 0;
      end
    end
      else if ((!core_flush_i&can_commit_non_specs&performing_system_operation&(meu_type_i[1])&meu_vld_i)) begin
      fence_exec <= 1;
    end
  end

  assign rs1_o = meu_rs1_i;
  assign rs2_o = meu_rs2_i;
  assign p2_we_data = tmu_data_i;
  assign p2_we_dest = meu_dest_i;
  assign p2_we_i = (tmu_done_i & !tmu_excp_i) && p2_we_dest != 0;
  assign completed_rob_id = meu_rob_i[4:0];
  assign completion_valid = system_instruction_done;
  assign exception_o = tmu_done_i & tmu_excp_i;
  assign exception_code_o = 4'd2;
  assign exception_rob_o = meu_rob_i;
endmodule
