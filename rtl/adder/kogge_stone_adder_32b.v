`timescale 1ns / 1ps

// 32-bit Kogge-Stone parallel-prefix adder with external carry-in.
module kogge_stone_adder_32b(
    input  [31:0] a,
    input  [31:0] b,
    input         cin,
    output [31:0] sum,
    output        cout
);
    wire [31:0] p0, g0;
    wire [31:0] p1, g1;
    wire [31:0] p2, g2;
    wire [31:0] p3, g3;
    wire [31:0] p4, g4;
    wire [31:0] p5, g5;
    wire [32:0] c;

    assign p0 = a ^ b;
    assign g0 = a & b;

    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : STAGE1
            if (i >= 1) begin
                assign g1[i] = g0[i] | (p0[i] & g0[i-1]);
                assign p1[i] = p0[i] & p0[i-1];
            end else begin
                assign g1[i] = g0[i];
                assign p1[i] = p0[i];
            end
        end
        for (i = 0; i < 32; i = i + 1) begin : STAGE2
            if (i >= 2) begin
                assign g2[i] = g1[i] | (p1[i] & g1[i-2]);
                assign p2[i] = p1[i] & p1[i-2];
            end else begin
                assign g2[i] = g1[i];
                assign p2[i] = p1[i];
            end
        end
        for (i = 0; i < 32; i = i + 1) begin : STAGE3
            if (i >= 4) begin
                assign g3[i] = g2[i] | (p2[i] & g2[i-4]);
                assign p3[i] = p2[i] & p2[i-4];
            end else begin
                assign g3[i] = g2[i];
                assign p3[i] = p2[i];
            end
        end
        for (i = 0; i < 32; i = i + 1) begin : STAGE4
            if (i >= 8) begin
                assign g4[i] = g3[i] | (p3[i] & g3[i-8]);
                assign p4[i] = p3[i] & p3[i-8];
            end else begin
                assign g4[i] = g3[i];
                assign p4[i] = p3[i];
            end
        end
        for (i = 0; i < 32; i = i + 1) begin : STAGE5
            if (i >= 16) begin
                assign g5[i] = g4[i] | (p4[i] & g4[i-16]);
                assign p5[i] = p4[i] & p4[i-16];
            end else begin
                assign g5[i] = g4[i];
                assign p5[i] = p4[i];
            end
        end
    endgenerate

    assign c[0] = cin;
    generate
        for (i = 0; i < 32; i = i + 1) begin : CARRY_AND_SUM
            assign c[i+1] = g5[i] | (p5[i] & cin);
            assign sum[i] = p0[i] ^ c[i];
        end
    endgenerate
    assign cout = c[32];
endmodule
