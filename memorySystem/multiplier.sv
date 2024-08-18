module multiplier (
    input   wire logic          clk_i,
    input   wire logic          rst_i,

    input   wire logic [31:0]   a_i,
    input   wire logic [31:0]   b_i,
    input   wire logic [1:0]    opcode_i,
    input   wire logic          valid,

    output       logic [31:0]   result,
    output       logic          vld_o
);
    reg [31:0] a;
    reg [31:0] b;
    reg valid_r;
    reg counter;
    reg [1:0] opcode;
    reg sign;
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            valid_r <= 1'b0;
        end
        else if (valid&!valid_r) begin
            valid_r <= 1'b1;
            a <= opcode_i==2'b11|~a_i[31] ? a_i : ~a_i + 1'b1;
            b <= opcode_i[1]|~b_i[31] ? b_i : ~b_i + 1'b1;
            opcode <= opcode_i; 
            sign <= opcode==2'b00 ? a_i[31]^b_i[31] : opcode[0]^opcode[1] ? a_i[31] : 1'b0;
        end else if (counter) begin
            valid_r <= 1'b0;
        end
    end

    wire [63:0] multiplication_result = a*b;

    reg [63:0] reg_multiplication_result;

    always_ff @(posedge clk_i) begin
        if (valid_r&!rst_i) begin
            reg_multiplication_result <= multiplication_result;
        end
    end

    wire [31:0] final_result = opcode == 2'b00 ? sign ? ~reg_multiplication_result[31:0] + 1'b1 : reg_multiplication_result[31:0] :
                                                 sign ? ~reg_multiplication_result[63:32] + 1'b1 : reg_multiplication_result[63:32];

    always_ff @(posedge clk_i) begin
        if (counter&!rst_i) begin
            result <= final_result;
            vld_o <= 1'b1;
        end else begin
            vld_o <= 1'b0;
        end
    end
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            counter <= 1'b0;
        end
        else if (valid&!valid_r) begin
            counter <= 0;
        end
        else if (valid_r) begin
            if (counter) begin
                counter <= 1'b0;
            end
            else begin
                counter <= counter + 1'b1;
            end
        end 
    end
endmodule
