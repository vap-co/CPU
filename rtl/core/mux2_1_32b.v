`timescale 1ns / 1ps

module mux2_1_32b(
    input  [31:0] in0,
    input  [31:0] in1,
    input         sel,
    output [31:0] out
);

    assign out = sel ? in1 : in0;

endmodule
