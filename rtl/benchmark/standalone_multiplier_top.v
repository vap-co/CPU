`timescale 1ns / 1ps

// Input and output registers define the measured multiplier path.
module standalone_multiplier_top #(
    parameter MULT_TYPE = 0
)(
    input         clk,
    input  [31:0] a_in,
    input  [31:0] b_in,
    output reg [63:0] product_out
);
    reg [31:0] a_reg, b_reg;
    wire [63:0] product_comb;

    cpu_multiplier_32b #(.MULT_TYPE(MULT_TYPE)) dut(
        .a(a_reg), .b(b_reg), .product(product_comb)
    );

    always @(posedge clk) begin
        a_reg       <= a_in;
        b_reg       <= b_in;
        product_out <= product_comb;
    end
endmodule
