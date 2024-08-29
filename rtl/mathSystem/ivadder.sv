module ivadder (
    input   wire logic [31:0]   a,
    input   wire logic [31:0]   b,
    input   wire logic [2:0]    op,
    input   wire logic          size,

    output  wire logic [31:0]   result
);
    wire [8:0] psum0, psum1, psum2, psum3;
    
    wire cin0, cin1, cin2, cin3;
    wire inv = op[0];
    wire [31:0] b_2 = inv ? ~b : b;
    assign psum0 = a[7:0] + b_2[7:0] + {7'h0, cin0};
    assign psum1 = a[15:8] + b_2[15:8] + {7'h0, cin1};
    assign psum2 = a[23:16] + b_2[23:16] + {7'h0, cin2};
    assign psum3 = a[31:24] + b_2[31:24] + {7'h0, cin3};

    assign cin0 = op[0];
    assign cin1 = (psum0[8]&(|size))|(op[0]&!(|size));
    assign cin2 = op[0];
    assign cin3 = psum2[8]&(|size)|(op[0]&!(|size));

    wire isSaturating = op[2];
    wire isSigned = op[1];

    // 0x8000 signed INT_MIN
    wire [3:0] carry_used = {psum3[8], size==1 ? psum3[8] : psum2[8], psum1[8], size==1 ? psum1[8] : psum0[8]};
    wire [3:0] top_bit    = {psum3[7], size==1 ? psum3[7] : psum2[7], psum1[7], size==1 ? psum1[7] : psum0[7]};
    wire [7:0] unsigned_max = 8'hFF;
    wire [7:0] unsigned_min = 8'h00;
    wire [7:0] signed_max   = 8'h7F;
    wire [7:0] signed_min   = 8'h80;
    wire [3:0] argument_top_bit = {a[31], size==1 ? a[31] : a[23], a[15], size==1 ? a[15] : a[7]};
    wire [3:0] signs_equal = {a[31]==b[31], size==1 ? a[31]==b[31] : a[23]==b[23], a[15]==b[15], size==1 ? a[15]==b[15] : a[7]==b[7]};
    wire [3:0] sign_condition = op[0] ? ~signs_equal : signs_equal;
    wire [3:0] signedSaturate = sign_condition&(top_bit^argument_top_bit);
    assign result = {
    isSaturating ? isSigned&signedSaturate[3] ? argument_top_bit[3] ? signed_min : signed_max : !isSigned&carry_used[3] ? op[0] ? unsigned_min : unsigned_max : psum3[7:0] : psum3[7:0],
    isSaturating ? isSigned&signedSaturate[2] ? argument_top_bit[2] ? size==1 ? 8'h00 : signed_min : size==1 ? 8'hFF : signed_max : !isSigned&carry_used[2] ? op[0] ? unsigned_min : unsigned_max : psum2[7:0] : psum2[7:0],
    isSaturating ? isSigned&signedSaturate[1] ? argument_top_bit[1] ? signed_min : signed_max : !isSigned&carry_used[1] ? op[0] ? unsigned_min : unsigned_max : psum1[7:0] : psum1[7:0], 
    isSaturating ? isSigned&signedSaturate[0] ? argument_top_bit[0] ? size==1 ? 8'h00 : signed_min : size==1 ? 8'hFF : signed_max : !isSigned&carry_used[0] ? op[0] ? unsigned_min : unsigned_max : psum0[7:0] : psum0[7:0]};
endmodule
