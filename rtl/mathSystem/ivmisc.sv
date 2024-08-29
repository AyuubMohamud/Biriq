module ivmisc (
    input   wire logic [31:0]   a,
    input   wire logic [31:0]   b,
    input   wire logic [1:0]    op,
    input   wire logic          size,

    output  wire logic [31:0]   result_o
);

    wire [3:0] plc0;
    wire [3:0] plc1;
    wire [3:0] plc2;
    wire [3:0] plc3;
    plc8 plc8_0 (a[7:0], plc0);
    plc8 plc8_1 (a[15:8], plc1);
    plc8 plc8_2 (a[23:16], plc2);
    plc8 plc8_3 (a[31:24], plc3);

    wire [4:0] plc0_16 = plc0+plc1;
    wire [4:0] plc1_16 = plc2+plc3;
    wire [31:0] plc_result = size ? {11'h0, plc1_16, 11'h0, plc0_16} : 
    {4'h0, plc3, 4'h0, plc2, 4'h0, plc1, 4'h0, plc0};

    wire [3:0] clz0;
    wire [3:0] clz1;
    wire [3:0] clz2;
    wire [3:0] clz3;

    
    clz8 clz8_0 (a[7:0], clz0  );
    clz8 clz8_1 (a[15:8], clz1  );
    clz8 clz8_2 (a[23:16], clz2 );
    clz8 clz8_3 (a[31:24], clz3 );

    wire [31:0] clz_8 = {{4'h0, clz3},{4'h0, clz2},{4'h0, clz1},{4'h0, clz0}};
    wire [31:0] clz_16 = {
    {clz3[3]&clz2[3]? 16'd16 : !clz2[3] ? {12'h0, clz2} : {11'h0, clz3, 1'h0}},
    {clz1[3]&clz0[3]? 16'd16 : !clz0[3] ? {12'h0, clz0} : {11'h0, clz1, 1'h0}}
    };
    wire [31:0] clz_result = size ? clz_16 : clz_8;

    wire [1:0] byte_select_index [0:7];
    assign byte_select_index[0] = !size ? b[1:0]   : {b[0],1'b0};
    assign byte_select_index[1] = !size ? b[9:8]   : {b[0],1'b1};
    assign byte_select_index[2] = !size ? b[17:16] : {b[16],1'b0};
    assign byte_select_index[3] = !size ? b[25:24] : {b[16],1'b1};

    wire [31:0] sel_result;
    for (genvar i = 0; i < 4; i++) begin : generateByteSelectLogic
        byteselect byteselect_inst (a, byte_select_index[i], sel_result[((i+1)*8)-1:i*8]);
    end


    assign result_o = op[1:0] == 2'b00 ? clz_result : op[1:0]==2'b01 ? plc_result : sel_result;

endmodule
