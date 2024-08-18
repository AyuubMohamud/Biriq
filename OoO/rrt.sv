module rrt (
    input   wire logic              cpu_clk_i,

    input   wire logic [5:0]        phys_reg_wr0,
    input   wire logic              phys_reg_wr_vld0,
    
    input   wire logic [5:0]        phys_reg_wr1,
    input   wire logic              phys_reg_wr_vld1,

    input   wire logic [5:0]        phys_reg_disp0,
    input   wire logic              phys_reg_disp_vld0,
    
    input   wire logic [5:0]        phys_reg_disp1,
    input   wire logic              phys_reg_disp_vld1,

    output  wire logic              safe_to_free0,
    output  wire logic              safe_to_free1
);
    reg [5:0] register_ref_tbl0 [0:63];

    for (genvar i = 0; i < 32; i++) begin : _
        initial begin
            register_ref_tbl0[i] = 6'b000001;
        end
    end
    reg [5:0] register_ref_tbl1 [0:63];
    reg [5:0] register_ref_tbl2 [0:63];
    reg [5:0] register_ref_tbl3 [0:63];

    wire [5:0] cr0;
    wire [5:0] cr1;
    wire [5:0] cr2;
    wire [5:0] cr3;
    assign cr0 = register_ref_tbl0[phys_reg_wr0] ^ register_ref_tbl1[phys_reg_wr0] ^ register_ref_tbl2[phys_reg_wr0] ^ register_ref_tbl3[phys_reg_wr0];
    assign cr1 = register_ref_tbl0[phys_reg_wr1] ^ register_ref_tbl1[phys_reg_wr1] ^ register_ref_tbl2[phys_reg_wr1] ^ register_ref_tbl3[phys_reg_wr1];
    assign cr2 = register_ref_tbl0[phys_reg_disp0] ^ register_ref_tbl1[phys_reg_disp0] ^ register_ref_tbl2[phys_reg_disp0] ^ register_ref_tbl3[phys_reg_disp0];
    assign cr3 = register_ref_tbl0[phys_reg_disp1] ^ register_ref_tbl1[phys_reg_disp1] ^ register_ref_tbl2[phys_reg_disp1] ^ register_ref_tbl3[phys_reg_disp1];

    wire written_twice;
    wire displaced_twice;
    assign written_twice = (phys_reg_wr0 == phys_reg_wr1) & phys_reg_wr_vld0 & phys_reg_wr_vld1;
    assign displaced_twice = (phys_reg_disp0 == phys_reg_disp1) & phys_reg_disp_vld0 & phys_reg_disp_vld1;
    wire wr0_disp0_equ = (phys_reg_disp0==phys_reg_wr0);
    wire wr1_disp0_equ = (phys_reg_disp0==phys_reg_wr1);
    wire wr0_disp1_equ = (phys_reg_disp1==phys_reg_wr0);
    wire wr1_disp1_equ = (phys_reg_disp1==phys_reg_wr1);

    wire written_once_wr0 = (phys_reg_wr_vld0) && (written_twice ? !(((wr0_disp0_equ)&&phys_reg_disp_vld0)&&((wr0_disp1_equ)&&phys_reg_disp_vld1))
    : !(((wr0_disp0_equ)&&phys_reg_disp_vld0)||((wr0_disp1_equ)&&phys_reg_disp_vld1))); 
    wire written_once_wr1 = !written_twice&& (phys_reg_wr_vld1) && !(((phys_reg_disp0==phys_reg_wr1)&&phys_reg_disp_vld0)||((phys_reg_disp1==phys_reg_wr1)&&phys_reg_disp_vld1)); 
    wire written_twice_wr0 = written_twice&!((wr0_disp0_equ&phys_reg_disp_vld0)||(wr0_disp1_equ&phys_reg_disp_vld1));
    wire displaced_once_disp0 = (phys_reg_disp_vld0) && (displaced_twice ? !(((wr0_disp0_equ)&&phys_reg_wr_vld0)&&((wr1_disp0_equ)&&phys_reg_wr_vld1))
    : !(((wr0_disp0_equ)&&phys_reg_wr_vld0)||((wr1_disp0_equ)&&phys_reg_wr_vld1)));
    wire displaced_once_disp1 = !displaced_twice && (phys_reg_disp_vld1) && !(((wr0_disp1_equ)&&phys_reg_wr_vld0)||((wr1_disp1_equ)&&phys_reg_wr_vld1));
    wire displaced_twice_disp0 = displaced_twice&!((wr0_disp0_equ&phys_reg_wr_vld0)||(wr1_disp0_equ&phys_reg_wr_vld1));
    wire [5:0] cr0_nx;
    wire [5:0] cr1_nx;
    wire [5:0] cr2_nx;
    wire [5:0] cr3_nx;
    wire [5:0] inc_num0 = written_twice_wr0 ? 6'b000010 : written_once_wr0 ? 6'b000001 : 6'b000000;
    wire [5:0] inc_num1 = written_once_wr1 ? 6'b000001 : 6'b000000;
    wire [5:0] dec_num0 = displaced_twice_disp0 ? 6'b000010 : displaced_once_disp0 ? 6'b000001 : 6'b000000;
    wire [5:0] dec_num1 = displaced_once_disp1 ? 6'b000001 : 6'b000000;
    assign cr0_nx = cr0+inc_num0;
    assign cr1_nx = cr1+inc_num1;
    assign cr2_nx = cr2-dec_num0;
    assign cr3_nx = cr3-dec_num1;
    assign safe_to_free0 = cr2_nx==0;
    assign safe_to_free1 = !displaced_twice && cr3_nx==0;
    always_ff @(posedge cpu_clk_i) begin
        register_ref_tbl0[phys_reg_wr0] <= cr0_nx^
        register_ref_tbl1[phys_reg_wr0] ^ register_ref_tbl2[phys_reg_wr0] ^ register_ref_tbl3[phys_reg_wr0];
        register_ref_tbl1[phys_reg_wr1] <= cr1_nx^
        register_ref_tbl0[phys_reg_wr1] ^ register_ref_tbl2[phys_reg_wr1] ^ register_ref_tbl3[phys_reg_wr1];
        register_ref_tbl2[phys_reg_disp0] <=  cr2_nx^
        register_ref_tbl1[phys_reg_disp0] ^ register_ref_tbl0[phys_reg_disp0] ^ register_ref_tbl3[phys_reg_disp0];
        register_ref_tbl3[phys_reg_disp1] <= cr3_nx^
        register_ref_tbl1[phys_reg_disp1] ^ register_ref_tbl2[phys_reg_disp1] ^ register_ref_tbl0[phys_reg_disp1];
    end

endmodule
