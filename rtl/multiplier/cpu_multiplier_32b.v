`timescale 1ns / 1ps

// MULT_TYPE: 0=Array, 1=Wallace, 2=Vedic
module cpu_multiplier_32b #(
    parameter MULT_TYPE = 0
)(
    input  [31:0] a,
    input  [31:0] b,
    output [63:0] product
);
    generate
        if (MULT_TYPE == 0) begin : GEN_ARRAY
            array_multiplier_32b u_mul(.a(a), .b(b), .product(product));
        end else if (MULT_TYPE == 1) begin : GEN_WALLACE
            wallace_multiplier_32b u_mul(.a(a), .b(b), .product(product));
        end else begin : GEN_VEDIC
            vedic_multiplier_32b u_mul(.a(a), .b(b), .product(product));
        end
    endgenerate
endmodule
