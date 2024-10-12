module pmpdecode32 (
    input   wire logic [29:0] address,
    output       logic [29:0] mask,
    output       logic [29:0] match_address
);
    logic finishs;
    logic finishs2;
    always_comb begin
        mask = '1;
        match_address = address;
        finishs = '0;
        finishs2 = '0;
        for (integer i = 0; i < 30; i++) begin
            if (!finishs&address[i]) begin
                mask[i] = 0;
                finishs = 1;
            end
        end
        for (integer i = 0; i < 30; i++) begin
            if (!finishs2&address[i]) begin
                match_address[i] = 0;
                finishs2 = 1;
            end
        end
    end

endmodule
