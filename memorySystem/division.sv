// Project F Library - Division: Unsigned Integer with Remainder
// (C)2023 Will Green, Open source hardware released under the MIT License
// Learn more at https://projectf.io/verilog-lib/
// Expanded to support all divison opcodes in riscv by Ayuub Mohamud

module division ( 
    input wire logic clk,              // clock
    input wire logic rst,              // reset
    input wire logic start,            // start calculation
    input wire logic unsigned_i,
    output     logic busy,             // calculation in progress
    output     logic done,             // calculation is complete (high for one tick)
    output     logic valid,            // result is valid
    output     logic dbz,              // divide by zero
    output     logic overflow,
    input wire logic [31:0] a_i,    // dividend (numerator)
    input wire logic [31:0] b_i,    // divisor (denominator)
    output     logic [31:0] val,  // result value: quotient
    output     logic [31:0] rem   // result: remainder
);

    logic [31:0] b1;             // copy of divisor
    logic [31:0] quo, quo_next;  // intermediate quotient
    logic [32:0] acc, acc_next;    // accumulator (1 bit wider)
    logic [$clog2(32)-1:0] i;      // iteration counter
    logic unsigned_r;
    logic sign;
    wire [31:0] a;
    wire [31:0] b;
    assign a = unsigned_i|~a_i[31] ? a_i : ~a_i+1'b1;
    assign b = unsigned_i|~b_i[31] ? b_i : ~b_i+1'b1;
    // division algorithm iteration
    always_comb begin
        if (acc >= {1'b0, b1}) begin
            acc_next = acc - b1;
            {acc_next, quo_next} = {acc_next[31:0], quo, 1'b1};
        end else begin
            {acc_next, quo_next} = {acc, quo} << 1;
        end
    end

    // calculation control
    wire [31:0] remainder = unsigned_r|~sign ? acc_next[32:1] : ~acc_next[32:1] + 1'b1; 
    wire [31:0] quotient = unsigned_r|~sign ? quo_next : ~quo_next + 1'b1;
    always_ff @(posedge clk) begin   
        if (rst) begin
            busy <= 0;
            done <= 0;
            valid <= 0;
            dbz <= 0;
            val <= 0;
            rem <= 0;
            unsigned_r <= 1'b0;
            sign <= 1'b0;
            acc <= 33'd0;
            quo <= 32'd0;
            b1 <= 32'd0;
        end
        else if (start) begin
            valid <= 0;
            i <= 0;
            if (b == 0) begin  // catch divide by zero
                busy <= 0;
                done <= 1;
                dbz <= 1;
                overflow <= 0;
            end
            else if (a_i==32'h80000000 && b_i==32'hFFFFFFFF && !unsigned_i) begin // catch overflow
                busy <= 0;
                done <= 1;
                dbz <= 0;
                overflow <= 1;
            end else begin
                busy <= 1;
                dbz <= 0;
                overflow <= 0;
                b1 <= b;
                unsigned_r <= unsigned_i;
                sign <= a[31]^b[31];
                {acc, quo} <= {{32{1'b0}}, a, 1'b0};  // initialize calculation
            end
        end else if (busy) begin
            if (i == 5'b11111) begin  // we're done
                busy <= 0;
                done <= 1;
                valid <= 1;
                val <= quotient;
                rem <= remainder;  // undo final shift
            end else begin  // next iteration
                i <= i + 1;
                acc <= acc_next;
                quo <= quo_next;
            end
        end else begin
            done <= 1'b0;
        end
    end
endmodule
