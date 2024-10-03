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

    wire [3:0] ctz0;
    wire [3:0] ctz1;
    wire [3:0] ctz2;
    wire [3:0] ctz3;

    
    ctz8 ctz8_0 (a[7:0], ctz0  );
    ctz8 ctz8_1 (a[15:8], ctz1  );
    ctz8 ctz8_2 (a[23:16], ctz2 );
    ctz8 ctz8_3 (a[31:24], ctz3 );

    wire [31:0] ctz_8 = {{4'h0, ctz3},{4'h0, ctz2},{4'h0, ctz1},{4'h0, ctz0}};
    wire [31:0] ctz_16 = {
    {ctz3[3]&ctz2[3]? 16'd16 : !ctz2[3] ? {12'h0, ctz2} : {11'h0, ctz3, 1'h0}},
    {ctz1[3]&ctz0[3]? 16'd16 : !ctz0[3] ? {12'h0, ctz0} : {11'h0, ctz1, 1'h0}}
    };
    wire [31:0] ctz_result = size ? ctz_16 : ctz_8;

    wire [1:0] byte_select_index [0:7];
    assign byte_select_index[0] = !size ? b[1:0]   : {b[0],1'b0};
    assign byte_select_index[1] = !size ? b[9:8]   : {b[0],1'b1};
    assign byte_select_index[2] = !size ? b[17:16] : {b[16],1'b0};
    assign byte_select_index[3] = !size ? b[25:24] : {b[16],1'b1};

    wire [31:0] sel_result;
    for (genvar i = 0; i < 4; i++) begin : generateByteSelectLogic
        byteselect byteselect_inst (a, byte_select_index[i], sel_result[((i+1)*8)-1:i*8]);
    end


    assign result_o = op[1:0] == 2'b00 ? ctz_result : op[1:0]==2'b01 ? plc_result : sel_result;

endmodule
