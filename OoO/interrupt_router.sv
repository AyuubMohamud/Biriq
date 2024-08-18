module interrupt_router (
    input   wire logic              current_privilege_mode,
    input   wire logic              mie,
    input   wire logic [2:0]        machine_interrupts,

    output  wire logic              int_o,
    output  wire logic [3:0]        int_type
);
    
    wire go_to_M = (((current_privilege_mode)&&mie)||(!current_privilege_mode)) && ((|machine_interrupts));

    wire [3:0] enc_M_only = machine_interrupts[2] ? 4'd11 :
                            machine_interrupts[0] ? 4'd3 :
                            4'd7;

    assign int_o = go_to_M;
    assign int_type = enc_M_only;
endmodule
