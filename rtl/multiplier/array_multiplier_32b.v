`timescale 1ns / 1ps

// Unsigned 32x32 multiplier: partial products, linear CSA reduction, final RCA.

// Carry output from bit k feeds bit k+1 in the next reduction row.
module array_csa_row_64b (
    input  wire [63:0] x,
    input  wire [63:0] y,
    input  wire [63:0] z,
    output wire [63:0] sum,
    output wire [63:0] carry
);
    wire [63:0] carry_raw;
    genvar k;

    generate
        for (k = 0; k < 64; k = k + 1) begin : GEN_CSA_FA
            full_adder u_fa (
                .a   (x[k]),
                .b   (y[k]),
                .cin (z[k]),
                .sum (sum[k]),
                .cout(carry_raw[k])
            );
        end
    endgenerate

    assign carry[0]    = 1'b0;
    assign carry[63:1] = carry_raw[62:0];
    // Bit 64 is outside the 64-bit product.
endmodule

// Final carry-propagate adder.
module array_final_rca_64b (
    input  wire [63:0] a,
    input  wire [63:0] b,
    output wire [63:0] sum
);
    wire [64:0] c;
    genvar k;

    assign c[0] = 1'b0;

    generate
        for (k = 0; k < 64; k = k + 1) begin : GEN_FINAL_FA
            full_adder u_fa (
                .a   (a[k]),
                .b   (b[k]),
                .cin (c[k]),
                .sum (sum[k]),
                .cout(c[k+1])
            );
        end
    endgenerate
endmodule

(* use_dsp = "no" *)
module array_multiplier_32b (
    input  wire [31:0] a,
    input  wire [31:0] b,
    output wire [63:0] product
);
    wire [63:0] pp [0:31];

    wire [63:0] stage_sum   [0:29];
    wire [63:0] stage_carry [0:29];

    genvar i;

    // pp[i] = (a & b[i]) << i
    generate
        for (i = 0; i < 32; i = i + 1) begin : GEN_PARTIAL_PRODUCTS
            assign pp[i] = ({32'b0, (a & {32{b[i]}})}) << i;
        end
    endgenerate

    array_csa_row_64b u_csa_row0 (
        .x    (pp[0]),
        .y    (pp[1]),
        .z    (pp[2]),
        .sum  (stage_sum[0]),
        .carry(stage_carry[0])
    );

    // Add one partial-product row per CSA stage.
    generate
        for (i = 1; i < 30; i = i + 1) begin : GEN_ARRAY_ROWS
            array_csa_row_64b u_csa_row (
                .x    (stage_sum[i-1]),
                .y    (stage_carry[i-1]),
                .z    (pp[i+2]),
                .sum  (stage_sum[i]),
                .carry(stage_carry[i])
            );
        end
    endgenerate

    array_final_rca_64b u_final_cpa (
        .a  (stage_sum[29]),
        .b  (stage_carry[29]),
        .sum(product)
    );

endmodule
