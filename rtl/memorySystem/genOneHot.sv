module genOneHot #(parameter WIDTH = 10) (
    input wire [WIDTH-1:0] bitvec,
    output logic onehot
);

    logic dectected_one;
    logic more_than_one;
    logic FINISHSEL;
    logic FINISHSEL2;
    logic [$clog2(WIDTH)-1:0] scan;
    always_comb begin
        dectected_one = '0;
        FINISHSEL = '0;
        scan = 0;
        for (integer i = 0; i < WIDTH; i++) begin
            if (bitvec[i]&!FINISHSEL) begin
                dectected_one = 1;
                FINISHSEL = 1;
                scan = i[$clog2(WIDTH)-1:0];
            end
        end
    end
    always_comb begin
        more_than_one = '0;
        FINISHSEL2 = '0;
        for (integer i = 0; i < WIDTH; i++) begin
            if (bitvec[i]&(i[$clog2(WIDTH)-1:0]!=scan)&&dectected_one&&!FINISHSEL2) begin
                more_than_one = 1;
                FINISHSEL2 = 1;
            end
        end
    end
    assign onehot = dectected_one&!more_than_one;
endmodule
