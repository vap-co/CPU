`timescale 1ns / 1ps

module ripple_carry_adder_32b(
    input  [31:0] a,
    input  [31:0] b,
    input         cin,
    output [31:0] sum,
    output        cout
);

    wire [32:0] c;
    
    assign c[0] = cin;
    assign cout = c[32];

    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : adder_loop
            full_adder fa (
                .a(a[i]),
                .b(b[i]),
                .cin(c[i]),
                .sum(sum[i]),
                .cout(c[i+1])
            );
        end
    endgenerate

endmodule
