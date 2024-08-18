module memory_scheduler (
    input   wire logic                          cpu_clk_i,
    input   wire logic                          flush_i,
    
    // interface from renamer
    input   wire logic                          renamer_pkt_vld_i,
    input   wire logic [5:0]                    pkt0_rs1_i,
    input   wire logic [5:0]                    pkt0_rs2_i,
    input   wire logic [5:0]                    pkt0_dest_i,
    input   wire logic [31:0]                   pkt0_immediate_i,
    input   wire logic [4:0]                    pkt0_ios_type_i,
    input   wire logic [2:0]                    pkt0_ios_opcode_i,
    input   wire logic [4:0]                    pkt0_rob_i,
    input   wire logic                          pkt0_vld_i,
    input   wire logic [5:0]                    pkt1_rs1_i,
    input   wire logic [5:0]                    pkt1_rs2_i,
    input   wire logic [5:0]                    pkt1_dest_i,
    input   wire logic [31:0]                   pkt1_immediate_i,
    input   wire logic [4:0]                    pkt1_ios_type_i,
    input   wire logic [2:0]                    pkt1_ios_opcode_i,
    input   wire logic                          pkt1_vld_i,
    output  wire logic                          full,
    // prf
    input   wire logic [31:0]                   rs1_data,
    output  wire logic [5:0]                    rs1_o,
    input   wire logic [31:0]                   rs2_data,
    output  wire logic [5:0]                    rs2_o,
    // register ready status
    output  wire logic [5:0]                    r4_vec_indx_o,
    input   wire logic                          r4_i,
    output  wire logic [5:0]                    r5_vec_indx_o,
    input   wire logic                          r5_i,
    // LSU inputs
    input   wire logic                          lsu_busy_i,
    output       logic                          lsu_vld_o,
    output       logic [5:0]                    lsu_rob_o,
    output       logic [3:0]                    lsu_op_o,
    output       logic [31:0]                   lsu_data_o,
    output       logic [31:0]                   lsu_addr_o,
    output       logic [5:0]                    lsu_dest_o,
    // Complex outputs
    output       logic  [2:0]                   cu_opcode_o,
    output       logic  [31:0]                  cu_operand1_o,
    output       logic  [31:0]                  cu_operand2_o,
    output       logic                          cu_valid_o,
    input  wire  logic                          busy_i,
    input  wire  logic  [31:0]                  result_i,
    input  wire  logic                          wb_valid_i,
    // csrfile inputs
    output   logic [31:0]                       tmu_data_o,
    output   logic [11:0]                       tmu_address_o,
    output   logic [1:0]                        tmu_opcode_o,
    output   logic                              tmu_wr_en,
    output   logic                              tmu_valid_o,
    input   wire logic                          tmu_done_i,
    input   wire logic                          tmu_excp_i,
    input   wire logic [31:0]                   tmu_data_i,
    input   wire logic                          store_buffer_empty,
    input   wire logic                          rob_lock,
    input   wire logic [4:0]                    rob_oldest_i,

    output  wire logic [4:0]                    completed_rob_id,
    output  wire logic                          completion_valid,
    output  wire logic                          exception_o,
    output  wire logic [5:0]                    exception_rob_o,
    output  wire logic [3:0]                    exception_code_o,
    output  wire logic                          p2_we_i,
    output  wire logic [31:0]                   p2_we_data,
    output  wire logic [5:0]                    p2_we_dest,

    output  wire logic                          dflush_o,
    input   wire logic                          d_can_flush
);
    initial tmu_valid_o = 0; initial lsu_vld_o = 0; initial cu_valid_o = 0;
    wire empty;
    wire issue;
    wire logic [5:0]                    pkt0_rs1;
    wire logic [5:0]                    pkt0_rs2;
    wire logic [5:0]                    pkt0_dest;
    wire logic [31:0]                   pkt0_immediate;
    wire logic [4:0]                    pkt0_ios_type;
    wire logic [2:0]                    pkt0_ios_opcode;
    wire logic [4:0]                    pkt0_rob;
    wire logic                          pkt0_vld;
    wire logic [5:0]                    pkt1_rs1;
    wire logic [5:0]                    pkt1_rs2;
    wire logic [5:0]                    pkt1_dest;
    wire logic [31:0]                   pkt1_immediate;
    wire logic [4:0]                    pkt1_ios_type;
    wire logic [2:0]                    pkt1_ios_opcode;
    wire logic                          pkt1_vld;
    sfifo2 #(.DW(123), .FW(8)) memfifo (cpu_clk_i, flush_i, !full&!flush_i&renamer_pkt_vld_i, {
        pkt0_rs1_i, pkt0_rs2_i, pkt0_dest_i, pkt0_immediate_i, pkt0_ios_type_i, pkt0_ios_opcode_i, pkt0_rob_i, pkt0_vld_i, pkt1_rs1_i, 
        pkt1_rs2_i, pkt1_dest_i, pkt1_immediate_i, pkt1_ios_type_i, pkt1_ios_opcode_i, pkt1_vld_i}, full, issue, {
    pkt0_rs1, pkt0_rs2, pkt0_dest, pkt0_immediate, pkt0_ios_type, pkt0_ios_opcode, pkt0_rob, pkt0_vld, pkt1_rs1, pkt1_rs2, 
    pkt1_dest, pkt1_immediate, pkt1_ios_type, pkt1_ios_opcode, pkt1_vld}, empty);

    reg packet_select;
    wire initial_packet_select = !pkt0_vld&pkt1_vld;
    wire actual_packet_select = initial_packet_select|packet_select;

    wire [5:0] packet_rs1 = actual_packet_select ? pkt1_rs1 : pkt0_rs1;
    wire [5:0] packet_rs2 = actual_packet_select ? pkt1_rs2 : pkt0_rs2;
    wire [5:0] packet_dest = actual_packet_select ? pkt1_dest : pkt0_dest;
    wire [31:0] packet_imm = actual_packet_select ? pkt1_immediate : pkt0_immediate;
    wire [4:0] packet_type = actual_packet_select ? pkt1_ios_type : pkt0_ios_type;
    wire [2:0] packet_opcode = actual_packet_select ? pkt1_ios_opcode : pkt0_ios_opcode;
    wire [5:0] packet_rob = actual_packet_select ? {pkt0_rob[4:0],1'b1} : {pkt0_rob[4:0],1'b0};
    wire packet_rs2_dependant = packet_type[3]|packet_type[0]; // a store
    assign rs1_o = packet_rs1;
    assign rs2_o = packet_rs2;
    assign r4_vec_indx_o = packet_rs1;
    assign r5_vec_indx_o = packet_rs2;
    reg csrfile_being_read;
    reg fence_exec; reg complex_performing = 0;
    wire performing_system_operation = |packet_type[2:1];
    wire system_instruction_done;
    wire packet_is_issueable = r4_i&!(!r5_i&packet_rs2_dependant)&!flush_i&!((performing_system_operation&!system_instruction_done)||(packet_type[0]&!wb_valid_i))&!lsu_busy_i&!rob_lock&!empty&!busy_i;
    assign issue = (pkt0_vld&!pkt1_vld)||(!pkt0_vld&pkt1_vld) ? packet_is_issueable : packet_is_issueable&packet_select;
    wire can_commit_non_specs = (packet_rob[4:0]==rob_oldest_i)&&!rob_lock;
    always_ff @(posedge cpu_clk_i) begin
        if (flush_i) begin
            lsu_vld_o <= 0;
        end
        else if (packet_is_issueable&(|packet_type[4:3])) begin
            lsu_addr_o <= rs1_data+packet_imm;
            lsu_data_o <= rs2_data;
            lsu_dest_o <= packet_dest;
            lsu_rob_o <= packet_rob;
            lsu_op_o <= {packet_type[3],packet_opcode};
            lsu_vld_o <= 1;
        end else if (!lsu_busy_i) begin
            lsu_vld_o <= 0;
        end
    end
    always_ff @(posedge cpu_clk_i) begin
        if (flush_i) begin
            cu_valid_o <= 0;
        end else if (complex_performing) begin
            cu_valid_o <= 0;
            if (wb_valid_i) begin
                complex_performing <= 0;
            end
        end else if (packet_type[0]&can_commit_non_specs&!empty) begin
            cu_valid_o <= 1; cu_opcode_o <= packet_opcode; cu_operand1_o <= rs1_data; cu_operand2_o <= rs2_data;
            complex_performing <= 1;
        end else begin
            cu_valid_o <= 0;
        end
    end
    always_ff @(posedge cpu_clk_i) begin
        if (flush_i) begin
            packet_select <= 1'b0;
        end
        else if (packet_is_issueable) begin
            packet_select <= pkt0_vld&pkt1_vld ? ~packet_select : (pkt0_vld&!pkt1_vld)|(!pkt0_vld&pkt1_vld) ? 1'b0 : 1'b1;
        end
    end

    // CSR File interaction
    assign system_instruction_done = (csrfile_being_read&tmu_done_i) ||
    ((store_buffer_empty)&&fence_exec);
    // system instructions require a flush sometimes
    always_ff @(posedge cpu_clk_i) begin : csrfile_modifications
        if (tmu_done_i) begin
            csrfile_being_read <= 0;
        end
        else if (((can_commit_non_specs&performing_system_operation&&(packet_type[2])))&!tmu_valid_o&!empty) begin
            csrfile_being_read <= 1'b1;
            tmu_opcode_o <= packet_opcode[1:0]; 
            tmu_data_o <= packet_opcode[2] ? {27'h0, packet_rs1[4:0]} : packet_opcode[1] ? {27'h0, rs1_data[4:0]} : rs1_data;
            tmu_address_o <= packet_imm[11:0];
            tmu_wr_en <= (packet_rs1!=0|packet_opcode[2]);
            tmu_valid_o <= 1;
        end else if (tmu_valid_o) begin
            tmu_valid_o <= 0;
        end
    end
    always_ff @(posedge cpu_clk_i) begin : fence_logic
        if (fence_exec) begin
            if ((store_buffer_empty&d_can_flush)) begin
                fence_exec <= 0;
            end
        end
        else if ((!flush_i&can_commit_non_specs&performing_system_operation&(packet_type[1])&!empty&d_can_flush)) begin
            fence_exec <= 1;
        end
    end
    assign p2_we_data = wb_valid_i ? result_i : tmu_data_i;
    assign p2_we_dest = packet_dest;
    assign p2_we_i = (tmu_done_i&!tmu_excp_i||(wb_valid_i))&&packet_dest!=0;
    assign completed_rob_id = packet_rob[4:0];
    assign completion_valid = system_instruction_done|wb_valid_i;
    assign exception_o = tmu_done_i&tmu_excp_i;
    assign exception_code_o = 4'd2;
    assign exception_rob_o = packet_rob;
    assign dflush_o = fence_exec&store_buffer_empty&d_can_flush;
endmodule
