`timescale 1ns / 1ps

// RV32M multiplication unit.
// funct3: 000=MUL, 001=MULH, 010=MULHSU, 011=MULHU
module mul_unit_32b #(
    parameter MULT_TYPE = 0
)(
    input  [31:0] a,
    input  [31:0] b,
    input  [2:0]  funct3,
    output [31:0] result
);
    wire a_signed = (funct3 == 3'b001) || (funct3 == 3'b010);
    wire b_signed = (funct3 == 3'b001);
    wire neg_a = a_signed && a[31];
    wire neg_b = b_signed && b[31];
    wire [31:0] mag_a = neg_a ? (~a + 32'd1) : a;
    wire [31:0] mag_b = neg_b ? (~b + 32'd1) : b;
    wire [63:0] unsigned_product;
    wire        neg_product = neg_a ^ neg_b;
    wire [63:0] signed_product = neg_product ? (~unsigned_product + 64'd1) : unsigned_product;

    cpu_multiplier_32b #(.MULT_TYPE(MULT_TYPE)) u_mul(
        .a(mag_a), .b(mag_b), .product(unsigned_product)
    );

    assign result = (funct3 == 3'b000) ? unsigned_product[31:0] : signed_product[63:32];
endmodule
