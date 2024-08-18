module skdbf #(parameter DW = 8) (
    input   wire logic          clk_i,
    input   wire logic          reset_i,
    // IP Side
    input   wire logic          combinational_busy_i,
    output  wire logic [DW-1:0] cycle_data_o,
    output  wire logic          cycle_vld_o,
    // Bus side
    output       logic          registered_busy_o,
    input   wire logic [DW-1:0] registered_data_i,
    input   wire logic          registered_vld_i 
);

    reg [DW-1:0] held_data;
    reg held_vld;
    initial held_vld = 0;
    initial held_data = 0;
    assign cycle_data_o = held_vld ? held_data : registered_data_i;
    assign cycle_vld_o = held_vld ? 1'b1 : registered_vld_i;

    wire hold_data;
    assign hold_data = combinational_busy_i & !registered_busy_o & cycle_vld_o & registered_vld_i;
    assign registered_busy_o = held_vld;

    always_ff @(posedge clk_i) begin
        if (reset_i) begin
            held_vld <= 1'b0;
            held_data <= 0;
        end else if (hold_data) begin
            held_data <= registered_data_i;
            held_vld <= 1'b1;
        end else if (!combinational_busy_i) begin
            held_vld <= 1'b0;
        end
    end 

endmodule
