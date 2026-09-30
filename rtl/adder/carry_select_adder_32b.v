`timescale 1ns / 1ps

// 32-bit Carry Select Adder (CSLA)
// Eight 4-bit blocks are used. The first block uses the real carry-in;
// every following block pre-computes results for carry-in 0 and 1.
module carry_select_adder_32b(
    input  [31:0] a,
    input  [31:0] b,
    input         cin,
    output [31:0] sum,
    output        cout
);
    wire [8:0] carry;
    assign carry[0] = cin;

    // First 4-bit block: true carry-in.
    wire [3:0] sum0;
    wire       c0_1, c0_2, c0_3, c0_4;
    full_adder fa00(.a(a[0]), .b(b[0]), .cin(carry[0]), .sum(sum0[0]), .cout(c0_1));
    full_adder fa01(.a(a[1]), .b(b[1]), .cin(c0_1),     .sum(sum0[1]), .cout(c0_2));
    full_adder fa02(.a(a[2]), .b(b[2]), .cin(c0_2),     .sum(sum0[2]), .cout(c0_3));
    full_adder fa03(.a(a[3]), .b(b[3]), .cin(c0_3),     .sum(sum0[3]), .cout(c0_4));
    assign sum[3:0] = sum0;
    assign carry[1] = c0_4;

    genvar blk;
    generate
        for (blk = 1; blk < 8; blk = blk + 1) begin : GEN_CSLA_BLOCK
            wire [3:0] s_c0;
            wire [3:0] s_c1;
            wire c00, c01, c02, c03;
            wire c10, c11, c12, c13;
            wire c_out0, c_out1;

            full_adder f0_0(.a(a[blk*4+0]), .b(b[blk*4+0]), .cin(1'b0), .sum(s_c0[0]), .cout(c00));
            full_adder f0_1(.a(a[blk*4+1]), .b(b[blk*4+1]), .cin(c00),  .sum(s_c0[1]), .cout(c01));
            full_adder f0_2(.a(a[blk*4+2]), .b(b[blk*4+2]), .cin(c01),  .sum(s_c0[2]), .cout(c02));
            full_adder f0_3(.a(a[blk*4+3]), .b(b[blk*4+3]), .cin(c02),  .sum(s_c0[3]), .cout(c03));
            assign c_out0 = c03;

            full_adder f1_0(.a(a[blk*4+0]), .b(b[blk*4+0]), .cin(1'b1), .sum(s_c1[0]), .cout(c10));
            full_adder f1_1(.a(a[blk*4+1]), .b(b[blk*4+1]), .cin(c10),  .sum(s_c1[1]), .cout(c11));
            full_adder f1_2(.a(a[blk*4+2]), .b(b[blk*4+2]), .cin(c11),  .sum(s_c1[2]), .cout(c12));
            full_adder f1_3(.a(a[blk*4+3]), .b(b[blk*4+3]), .cin(c12),  .sum(s_c1[3]), .cout(c13));
            assign c_out1 = c13;

            assign sum[blk*4 +: 4] = carry[blk] ? s_c1 : s_c0;
            assign carry[blk+1]    = carry[blk] ? c_out1 : c_out0;
        end
    endgenerate

    assign cout = carry[8];
endmodule
