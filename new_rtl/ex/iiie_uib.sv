module iiie_uib (
    input  wire        core_clock,
    input  wire [ 5:0] uib_op0_aluop,
    input  wire        uib_op0_alusela,
    input  wire        uib_op0_aluselb,
    input  wire [ 2:0] uib_op0_memop,
    input  wire [ 3:0] uib_op0_memprm,
    input  wire [ 1:0] uib_op0_memsz,
    input  wire [31:0] uib_op0_immediate,
    input  wire [ 1:0] uib_op0_hint,
    input  wire [ 5:0] uib_op0_dest,
    input  wire [ 2:0] uib_op0_type,
    input  wire [ 2:0] uib_op0_bcond,
    input  wire [ 5:0] uib_op1_aluop,
    input  wire        uib_op1_alusela,
    input  wire        uib_op1_aluselb,
    input  wire [ 2:0] uib_op1_memop,
    input  wire [ 3:0] uib_op1_memprm,
    input  wire [ 1:0] uib_op1_memsz,
    input  wire [31:0] uib_op1_immediate,
    input  wire [ 1:0] uib_op1_hint,
    input  wire [ 5:0] uib_op1_dest,
    input  wire [ 2:0] uib_op1_type,
    input  wire [ 2:0] uib_op1_bcond,
    input  wire [ 3:0] uib_pack_id,
    input  wire        uib_valid,
    output wire [ 5:0] uib_u_aluop,
    output wire        uib_u_alusela,
    output wire        uib_u_aluselb,
    output wire [31:0] uib_u_immediate,
    output wire [ 1:0] uib_u_hint,
    output wire [ 5:0] uib_u_dest,
    output wire [ 2:0] uib_u_type,
    output wire [ 2:0] uib_u_bcond,
    input  wire [ 4:0] uib_u_rob_id,
    output wire [ 5:0] uib_v_aluop,
    output wire        uib_v_alusela,
    output wire        uib_v_aluselb,
    output wire [ 2:0] uib_v_memop,
    output wire [ 3:0] uib_v_memprm,
    output wire [ 1:0] uib_v_memsz,
    output wire [31:0] uib_v_immediate,
    output wire [ 1:0] uib_v_hint,
    output wire [ 5:0] uib_v_dest,
    output wire [ 2:0] uib_v_type,
    input  wire [ 4:0] uib_v_rob_id
);
  reg [50:0] uib_bank0[0:15];
  reg [50:0] uib_bank1[0:15];
  reg [8:0] uib_membank0[0:15];
  reg [8:0] uib_membank1[0:15];
  reg [2:0] uib_bnchbank0[0:15];
  reg [2:0] uib_bnchbank1[0:15];

  always_ff @(posedge core_clock)
    if (uib_valid) begin
      uib_bank0[uib_pack_id] <= {
        uib_op0_aluop,
        uib_op0_alusela,
        uib_op0_aluselb,
        uib_op0_immediate,
        uib_op0_hint,
        uib_op0_dest,
        uib_op0_type
      };
      uib_bank1[uib_pack_id] <= {
        uib_op1_aluop,
        uib_op1_alusela,
        uib_op1_aluselb,
        uib_op1_immediate,
        uib_op1_hint,
        uib_op1_dest,
        uib_op1_type
      };
      uib_membank0[uib_pack_id] <= {uib_op0_memop, uib_op0_memprm, uib_op0_memsz};
      uib_membank1[uib_pack_id] <= {uib_op1_memop, uib_op1_memprm, uib_op1_memsz};
      uib_bnchbank0[uib_pack_id] <= uib_op0_bcond;
      uib_bnchbank1[uib_pack_id] <= uib_op1_bcond;
    end

  assign {uib_u_aluop,
uib_u_alusela,
uib_u_aluselb,
uib_u_immediate,
uib_u_hint,
uib_u_dest,
uib_u_type} = uib_u_rob_id[0] ? uib_bank1[uib_u_rob_id[4:1]] : uib_bank0[uib_u_rob_id[4:1]];
  assign {uib_v_aluop,
uib_v_alusela,
uib_v_aluselb,
uib_v_immediate,
uib_v_hint,
uib_v_dest,
uib_v_type} = uib_v_rob_id[0] ? uib_bank1[uib_v_rob_id[4:1]] : uib_bank0[uib_v_rob_id[4:1]];
  assign {uib_v_memop,
uib_v_memprm,
uib_v_memsz} = uib_v_rob_id[0] ? uib_membank1[uib_v_rob_id[4:1]] : uib_membank0[uib_v_rob_id[4:1]];
  assign uib_u_bcond = uib_u_rob_id[0] ? uib_bnchbank1[uib_u_rob_id[4:1]] : uib_bnchbank0[uib_u_rob_id[4:1]];

  
endmodule
