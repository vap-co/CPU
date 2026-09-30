`timescale 1ns / 1ps

module full_adder(
    input  a,
    input  b,
    input  cin,
    output sum,
    output cout
);
    wire s1;
    wire c1;
    wire c2;

    half_adder ha1(
        .a(a),
        .b(b),
        .sum(s1),
        .carry(c1)
    );

    half_adder ha2(
        .a(s1),
        .b(cin),
        .sum(sum),
        .carry(c2)
    );

    assign cout = c1 | c2;
endmodule
