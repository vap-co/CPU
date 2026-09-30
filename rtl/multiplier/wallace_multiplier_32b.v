`timescale 1ns / 1ps

module wallace_csa_64b(
    input  [63:0] x,
    input  [63:0] y,
    input  [63:0] z,
    output [63:0] sum,
    output [63:0] carry
);
    assign sum   = x ^ y ^ z;
    assign carry = ((x & y) | (x & z) | (y & z)) << 1;
endmodule

(* use_dsp = "no" *)
module wallace_multiplier_32b(
    input  [31:0] a,
    input  [31:0] b,
    output [63:0] product
);
    wire [63:0] pp [0:31];
    genvar gi;
    generate
        for (gi = 0; gi < 32; gi = gi + 1) begin : GEN_PP
            assign pp[gi] = b[gi] ? ({32'b0, a} << gi) : 64'b0;
        end
    endgenerate

    wire [63:0] l1 [0:21];
    wire [63:0] l2 [0:14];
    wire [63:0] l3 [0:9];
    wire [63:0] l4 [0:6];
    wire [63:0] l5 [0:4];
    wire [63:0] l6 [0:3];
    wire [63:0] l7 [0:2];
    wire [63:0] final_a, final_b;

    wallace_csa_64b l1_0(.x(pp[0]),  .y(pp[1]),  .z(pp[2]),  .sum(l1[0]),  .carry(l1[1]));
    wallace_csa_64b l1_1(.x(pp[3]),  .y(pp[4]),  .z(pp[5]),  .sum(l1[2]),  .carry(l1[3]));
    wallace_csa_64b l1_2(.x(pp[6]),  .y(pp[7]),  .z(pp[8]),  .sum(l1[4]),  .carry(l1[5]));
    wallace_csa_64b l1_3(.x(pp[9]),  .y(pp[10]), .z(pp[11]), .sum(l1[6]),  .carry(l1[7]));
    wallace_csa_64b l1_4(.x(pp[12]), .y(pp[13]), .z(pp[14]), .sum(l1[8]),  .carry(l1[9]));
    wallace_csa_64b l1_5(.x(pp[15]), .y(pp[16]), .z(pp[17]), .sum(l1[10]), .carry(l1[11]));
    wallace_csa_64b l1_6(.x(pp[18]), .y(pp[19]), .z(pp[20]), .sum(l1[12]), .carry(l1[13]));
    wallace_csa_64b l1_7(.x(pp[21]), .y(pp[22]), .z(pp[23]), .sum(l1[14]), .carry(l1[15]));
    wallace_csa_64b l1_8(.x(pp[24]), .y(pp[25]), .z(pp[26]), .sum(l1[16]), .carry(l1[17]));
    wallace_csa_64b l1_9(.x(pp[27]), .y(pp[28]), .z(pp[29]), .sum(l1[18]), .carry(l1[19]));
    assign l1[20] = pp[30];
    assign l1[21] = pp[31];

    wallace_csa_64b l2_0(.x(l1[0]),  .y(l1[1]),  .z(l1[2]),  .sum(l2[0]),  .carry(l2[1]));
    wallace_csa_64b l2_1(.x(l1[3]),  .y(l1[4]),  .z(l1[5]),  .sum(l2[2]),  .carry(l2[3]));
    wallace_csa_64b l2_2(.x(l1[6]),  .y(l1[7]),  .z(l1[8]),  .sum(l2[4]),  .carry(l2[5]));
    wallace_csa_64b l2_3(.x(l1[9]),  .y(l1[10]), .z(l1[11]), .sum(l2[6]),  .carry(l2[7]));
    wallace_csa_64b l2_4(.x(l1[12]), .y(l1[13]), .z(l1[14]), .sum(l2[8]),  .carry(l2[9]));
    wallace_csa_64b l2_5(.x(l1[15]), .y(l1[16]), .z(l1[17]), .sum(l2[10]), .carry(l2[11]));
    wallace_csa_64b l2_6(.x(l1[18]), .y(l1[19]), .z(l1[20]), .sum(l2[12]), .carry(l2[13]));
    assign l2[14] = l1[21];

    wallace_csa_64b l3_0(.x(l2[0]),  .y(l2[1]),  .z(l2[2]),  .sum(l3[0]), .carry(l3[1]));
    wallace_csa_64b l3_1(.x(l2[3]),  .y(l2[4]),  .z(l2[5]),  .sum(l3[2]), .carry(l3[3]));
    wallace_csa_64b l3_2(.x(l2[6]),  .y(l2[7]),  .z(l2[8]),  .sum(l3[4]), .carry(l3[5]));
    wallace_csa_64b l3_3(.x(l2[9]),  .y(l2[10]), .z(l2[11]), .sum(l3[6]), .carry(l3[7]));
    wallace_csa_64b l3_4(.x(l2[12]), .y(l2[13]), .z(l2[14]), .sum(l3[8]), .carry(l3[9]));

    wallace_csa_64b l4_0(.x(l3[0]), .y(l3[1]), .z(l3[2]), .sum(l4[0]), .carry(l4[1]));
    wallace_csa_64b l4_1(.x(l3[3]), .y(l3[4]), .z(l3[5]), .sum(l4[2]), .carry(l4[3]));
    wallace_csa_64b l4_2(.x(l3[6]), .y(l3[7]), .z(l3[8]), .sum(l4[4]), .carry(l4[5]));
    assign l4[6] = l3[9];

    wallace_csa_64b l5_0(.x(l4[0]), .y(l4[1]), .z(l4[2]), .sum(l5[0]), .carry(l5[1]));
    wallace_csa_64b l5_1(.x(l4[3]), .y(l4[4]), .z(l4[5]), .sum(l5[2]), .carry(l5[3]));
    assign l5[4] = l4[6];

    wallace_csa_64b l6_0(.x(l5[0]), .y(l5[1]), .z(l5[2]), .sum(l6[0]), .carry(l6[1]));
    wallace_csa_64b l6_1(.x(l5[3]), .y(l5[4]), .z(64'b0), .sum(l6[2]), .carry(l6[3]));

    wallace_csa_64b l7_0(.x(l6[0]), .y(l6[1]), .z(l6[2]), .sum(l7[0]), .carry(l7[1]));
    assign l7[2] = l6[3];

    wallace_csa_64b l8_0(.x(l7[0]), .y(l7[1]), .z(l7[2]), .sum(final_a), .carry(final_b));
    assign product = final_a + final_b;
endmodule
