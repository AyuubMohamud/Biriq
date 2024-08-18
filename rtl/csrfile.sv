module csrfile #(parameter [31:0] HARTID = 0) (
    input   wire logic                          cpu_clock_i,
    // CSR Interface
    input   wire logic [31:0]                   tmu_data_i,
    input   wire logic [11:0]                   tmu_address_i,
    input   wire logic [1:0]                    tmu_opcode_i,
    input   wire logic                          tmu_wr_en,
    //  001 - CSRRW, 010 - CSRRS, 011 - CSRRC,
    input   wire logic                          tmu_valid_i,
    output       logic                          tmu_done_o,
    output       logic                          tmu_excp_o,
    output       logic [31:0]                   tmu_data_o,
    // exception returns
    input   wire logic                          mret,
    // exception handling    
    input   wire logic                          take_exception,
    input   wire logic                          take_interrupt,
    input   wire logic [29:0]                   tmu_epc_i,
    input   wire logic [31:0]                   tmu_mtval_i,
    input   wire logic [3:0]                    tmu_mcause_i,

    input   wire logic                          tmu_msip_i,
    input   wire logic                          tmu_mtip_i,
    input   wire logic                          tmu_meip_i,
    // Signals for IQ state machine
    output  wire logic [2:0]                    tmu_mip_o,
    output  wire logic                          mie_o,
    input   wire logic                          inc_commit0,
    input   wire logic                          inc_commit1,
    output  wire logic                          mprv_o,

    // IQ
    output  wire logic                          real_privilege,
    output  wire logic [29:0]                   mepc_o,
    output  wire logic [31:0]                   mtvec_o,
    
    output  wire logic                          enable_branch_pred,
    output  wire logic                          enable_counter_overload,
    output  wire logic                          counter_overload
);
    /*Optimise before even thinking of putting this on an fpga*/
    reg current_privilege_mode = 1'b1; // Initially at 2'b11
    localparam MVENDORID = 12'hF11;
    localparam MARCHID = 12'hF12;
    localparam MIMPID = 12'hF13;
    localparam MHARTID = 12'hF14;
    localparam MCONFIGPTR = 12'hF15;

    reg [4:0] mstatus = 0; localparam MSTATUS = 12'h300; 
    localparam MISA = 12'h301;
    reg [2:0] mie = 0; localparam MIE = 12'h304;
    reg [31:0] mtvec = 0; localparam MTVEC = 12'h305;
    reg [1:0] mcounteren = 0; localparam MCOUNTEREN = 12'h306;
    localparam MSTATUSH = 12'h310;

    reg [31:0] mscratch = 0; localparam MSCRATCH = 12'h340;
    reg [29:0] mepc = 0; localparam MEPC = 12'h341;
    reg [4:0] mcause = 0; localparam MCAUSE = 12'h342;
    reg [31:0] mtval = 0; localparam MTVAL = 12'h343;
    reg [2:0] mip = 0; localparam MIP = 12'h344;
    assign mie_o = mstatus[3];
    localparam MENVCFG = 12'h30A;// fences are already implemented as total
    localparam MENVCFGH = 12'h31A; // RO ZERO

    // USER accessible CSRs
    reg [63:0] cycle = 0; localparam CYCLE = 12'hC00; localparam CYCLEH = 12'hC80; localparam MCYCLE = 12'hB00; localparam MCYCLEH = 12'hB80;
    reg [63:0] instret = 0; localparam INSTRET = 12'hC01; localparam INSTRETH = 12'hC81;localparam MINSTRET = 12'hB02; localparam MINSTRETH = 12'hB82;
    reg [1:0] mcountinhibit = 0; localparam MCOUNTERINHIBIT = 12'h320; 

    // Vendor-specific CSRs
    reg [2:0] siriusBrnchCtrl = 3'b100; localparam BRNCHCTRL = 12'h800;
    assign enable_branch_pred = siriusBrnchCtrl[2];
    assign enable_counter_overload = siriusBrnchCtrl[1];
    assign counter_overload = siriusBrnchCtrl[0];
    assign real_privilege = current_privilege_mode;
    assign tmu_mip_o = {tmu_meip_i, tmu_mtip_i, tmu_msip_i}&{mie[2], mie[1], mie[0]};
    assign mprv_o = mstatus[4];
    logic [31:0] read_data; logic exists;
    always_comb begin
        case (tmu_address_i)
            MVENDORID: begin read_data = 32'h0; exists = 1; end
            MIMPID: begin read_data = 32'h0;exists = 1; end
            MARCHID: begin read_data = 32'h0;exists = 1; end
            MHARTID: begin read_data = HARTID;exists = 1; end
            MCONFIGPTR: begin read_data = 32'h0;exists = 1; end
            MSTATUS: begin read_data = {14'h0, mstatus[4], 4'd0, mstatus[3:2], 3'd0, mstatus[1], 3'd0, mstatus[0], 3'd0};exists = 1; end
            MISA: begin read_data = 32'h40141100;exists = 1; end
            MIE: begin read_data = {20'h0,mie[2], 3'd0, mie[1], 3'd0, mie[0], 3'd0};exists = 1; end
            MIP: begin read_data = {20'h0,mip[2]|tmu_meip_i, 3'd0, mip[1]|tmu_mtip_i, 3'd0, mip[0]|tmu_msip_i, 3'd0};exists = 1;end
            MTVEC: begin read_data = mtvec;exists = 1;end
            MTVAL: begin read_data = mtval;exists = 1;end
            MSTATUSH: begin read_data = 32'h0;exists = 1;end
            MENVCFGH : begin read_data = 32'h0; exists = 1; end
            MENVCFG: begin read_data = 32'h0; exists = 1; end
            MCAUSE: begin read_data = {mcause[4], 27'h0,mcause[3:0]};exists = 1;end
            MSCRATCH: begin read_data = mscratch;exists = 1;end
            MEPC: begin read_data = {mepc,2'b00};exists = 1;end
            MCOUNTERINHIBIT: begin read_data = {29'h0,mcountinhibit[1],1'b0,mcountinhibit[0]};exists = 1;end
            MCYCLE: begin read_data = cycle[31:0];exists = 1;end
            MCYCLEH: begin read_data = cycle[63:32];exists = 1;end
            MINSTRET: begin read_data = instret[31:0];exists = 1;end
            MINSTRETH: begin read_data = instret[63:32];exists = 1;end
            MCOUNTEREN: begin read_data = {29'h0,mcounteren[1],1'b0,mcounteren[0]}; exists = 1; end
            CYCLE: begin read_data = cycle[31:0];exists = 1;end
            CYCLEH: begin read_data = cycle[63:32];exists = 1;end
            INSTRET: begin read_data = instret[31:0];exists = 1;end
            INSTRETH: begin read_data = instret[63:32];exists = 1;end
            BRNCHCTRL: begin read_data = {29'd0, siriusBrnchCtrl}; exists = 1; end
            default: begin
                read_data = 0; exists = 0;
            end
        endcase
    end
    wire [31:0] bit_sc = 1 << tmu_data_i[4:0];
    wire [31:0] new_data = tmu_opcode_i==2'b01 ? tmu_data_i : tmu_opcode_i==2'b10 ? read_data|bit_sc : read_data&~(bit_sc);
    always_ff @(posedge cpu_clock_i) begin
        if ((mret|take_exception|take_interrupt)) begin
            casez ({mret,take_exception, take_interrupt})
                3'b100: begin : MRET
                    if (current_privilege_mode) begin
                        // MAP: 17 -> 4, 12:11 -> 3:2 7 -> 1 3 -> 0
                        mstatus[0] <= mstatus[1]; // mpie->mie
                        mstatus[3:2] <= 2'b00; // machine mode is least supported mode
                        current_privilege_mode <= mstatus[3]&mstatus[2];
                        mstatus[1] <= 1;
                        mstatus[4] <= mstatus[4]&(mstatus[3:2]==2'b11); // mprv -> 0 when mpp!=M
                    end
                end
                3'b001: begin : Interrupt
                    mstatus[1] <= 1'b1;
                    mstatus[3:2] <= {current_privilege_mode,current_privilege_mode};
                    mstatus[0] <= 0; // mie
                    mepc<=tmu_epc_i;
                    mcause<={1'b1, tmu_mcause_i[3:0]};
                    mtval <= 0;
                    current_privilege_mode <= 1;
                end
                3'b010: begin : Exception
                    mstatus[1] <= mstatus[0];
                    mstatus[3:2] <= {current_privilege_mode,current_privilege_mode};
                    mstatus[0] <= 0;
                    mepc<=tmu_epc_i;
                    mcause<={1'b0,tmu_mcause_i[3:0]};
                    mtval <= tmu_mtval_i;current_privilege_mode <= 1;
                end
                default: begin
                    
                end
            endcase
            // MAP: 17 -> 4, 12:11 -> 3:2 7 -> 1 mstatus -> 0
        end else if (tmu_valid_i && tmu_wr_en && (current_privilege_mode)) begin
            case (tmu_address_i)
                MSTATUS: begin
                    mstatus[4] <= new_data[17];
                    mstatus[3:2] <= {new_data[12],new_data[12]};
                    mstatus[1] <= new_data[7];
                    mstatus[0] <= new_data[3]; 
                end
                MCAUSE: begin
                    mcause <= {new_data[31],new_data[3:0]};
                end
                MEPC: begin
                    mepc <= new_data[31:2];
                end
                MTVAL: begin
                    mtval <= new_data;
                end
                default: begin
                    
                end
            endcase
        end
    end

    always_ff @(posedge cpu_clock_i) begin
        if (tmu_valid_i&&tmu_wr_en&&(current_privilege_mode)) begin
            case (tmu_address_i)
                MSCRATCH: begin
                    mscratch <= new_data;
                end
                MTVEC: begin
                    mtvec[31:2] <= new_data[31:2];
                    mtvec[1:0] <= new_data[1:0] == 2'b00 ? 2'b00:
                                  new_data[1:0] == 2'b01 ? 2'b01:
                                  2'b00;
                end
                MIE: begin
                    mie[2] <= new_data[11];
                    mie[1] <=  new_data[7];
                    mie[0] <=  new_data[3];
                end
                MCOUNTERINHIBIT: begin
                    mcountinhibit[1] <= new_data[2];
                    mcountinhibit[0] <= new_data[0];
                end
                MCOUNTEREN: begin
                    mcounteren[0] <= new_data[0];
                    mcounteren[1] <= new_data[2];
                end
                default: begin
                    
                end
            endcase
        end
    end

    always_ff @(posedge cpu_clock_i) begin
        if (tmu_valid_i&&tmu_wr_en&&(current_privilege_mode)&&(tmu_address_i==MCYCLE)) begin
            cycle[31:0] <= new_data;
        end 
        else if (tmu_valid_i&&tmu_wr_en&&(current_privilege_mode)&&(tmu_address_i==MCYCLEH)) begin
            cycle[63:32] <= new_data;
        end else if (!mcountinhibit[0]) begin
            cycle <= cycle + 1;
        end
    end
    wire [63:0] constant = inc_commit0&inc_commit1 ? 64'd2 : 64'd1;
    always_ff @(posedge cpu_clock_i) begin
        if (tmu_valid_i&&tmu_wr_en&&(current_privilege_mode)&&(tmu_address_i==MINSTRET)) begin
            instret[31:0] <= new_data;
        end 
        else if (tmu_valid_i&&tmu_wr_en&&(current_privilege_mode)&&(tmu_address_i==MINSTRETH)) begin
            instret[63:32] <= new_data;
        end else if ((inc_commit0)&!mcountinhibit[1]) begin
            instret <= instret + constant;
        end
    end

    always_ff @(posedge cpu_clock_i) begin
        if (tmu_valid_i&&tmu_wr_en&&(tmu_address_i==BRNCHCTRL)) begin
            siriusBrnchCtrl <= new_data[2:0];
        end
    end

    always_ff @(posedge cpu_clock_i) begin
        tmu_data_o <= read_data;
    end
    assign mepc_o = mepc; assign mtvec_o = mtvec;
    initial tmu_done_o = 0;
    always_ff @(posedge cpu_clock_i) begin
        if (tmu_valid_i) begin
            tmu_done_o <= 1;
            tmu_excp_o <= ~((exists&&({current_privilege_mode,current_privilege_mode}>=tmu_address_i[9:8])&&!(tmu_wr_en&&(&tmu_address_i[11:10]))));
        end
        else begin
            tmu_done_o <= 0;
        end
    end
endmodule
