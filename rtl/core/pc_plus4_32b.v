`timescale 1ns / 1ps

module pc_plus4_32b(
    input  [31:0] pc,
    output [31:0] pc_plus4
);

    ripple_carry_adder_32b adder (
        .a(pc),
        .b(32'd4),
        .cin(1'b0),
        .sum(pc_plus4),
        .cout()
    );

endmodule
