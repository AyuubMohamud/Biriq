module amoalu (
    input   wire logic [31:0]   cpu_data,
    input   wire logic [31:0]   mem_data,
    input   wire logic          arith,
    input   wire logic [2:0]    op,
    output  wire logic [31:0]   new_data
);
    logic [31:0] arith_res;
    logic unsigned_cmp = cpu_data>mem_data;
    logic signed_cmp = $signed(cpu_data)>$signed(mem_data);
    always_comb begin
        arith_res = 'x;
        case (op)
            3'b000: begin
                arith_res = cpu_data+mem_data; 
            end
            3'b100: begin
                arith_res = unsigned_cmp ? cpu_data : mem_data;
            end
            3'b101: begin
                arith_res = !unsigned_cmp ? cpu_data : mem_data;
            end
            3'b110: begin
                arith_res = signed_cmp ? cpu_data : mem_data;
            end
            3'b111: begin
                arith_res = !signed_cmp ? cpu_data : mem_data;
            end
            default: begin
                arith_res = 'x;
            end
        endcase
    end

    wire [31:0] logic_res;
    assign logic_res = op[1:0]==2'b00 ? cpu_data : op[1:0]==2'b01 ? cpu_data&mem_data : op[1:0]==2'b10 ? cpu_data|mem_data : cpu_data^mem_data;

    assign new_data = arith ? arith_res : logic_res;
endmodule
