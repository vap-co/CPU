`timescale 1ns / 1ps

module branch_comp_32b(
    input      [31:0] dataR1,
    input      [31:0] dataR2,
    input             BrUn,
    output            BrEq,
    output            BrLT
);

    assign BrEq = (dataR1 == dataR2);

    assign BrLT = BrUn ? (dataR1 < dataR2) : ($signed(dataR1) < $signed(dataR2));

endmodule
