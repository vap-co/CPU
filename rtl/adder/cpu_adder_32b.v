`timescale 1ns / 1ps

// ADDER_TYPE: 0=RCA, 1=CSLA, 2=KSA
module cpu_adder_32b #(
    parameter ADDER_TYPE = 0
)(
    input  [31:0] a,
    input  [31:0] b,
    input         cin,
    output [31:0] sum,
    output        cout
);
    generate
        if (ADDER_TYPE == 0) begin : GEN_RCA
            ripple_carry_adder_32b u_adder(.a(a), .b(b), .cin(cin), .sum(sum), .cout(cout));
        end else if (ADDER_TYPE == 1) begin : GEN_CSLA
            carry_select_adder_32b u_adder(.a(a), .b(b), .cin(cin), .sum(sum), .cout(cout));
        end else begin : GEN_KSA
            kogge_stone_adder_32b u_adder(.a(a), .b(b), .cin(cin), .sum(sum), .cout(cout));
        end
    endgenerate
endmodule
