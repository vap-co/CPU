`timescale 1ns / 1ps

module vedic_multiplier_2b_full(
    input [1:0] a, input [1:0] b, output [3:0] product
);
    wire p0, p1, p2, p3, c1;
    assign p0 = a[0] & b[0];
    assign p1 = a[1] & b[0];
    assign p2 = a[0] & b[1];
    assign p3 = a[1] & b[1];
    assign product[0] = p0;
    assign product[1] = p1 ^ p2;
    assign c1 = p1 & p2;
    assign product[2] = p3 ^ c1;
    assign product[3] = p3 & c1;
endmodule

module vedic_multiplier_4b_full(
    input [3:0] a, input [3:0] b, output [7:0] product
);
    wire [3:0] p0,p1,p2,p3;
    vedic_multiplier_2b_full u0(.a(a[1:0]), .b(b[1:0]), .product(p0));
    vedic_multiplier_2b_full u1(.a(a[3:2]), .b(b[1:0]), .product(p1));
    vedic_multiplier_2b_full u2(.a(a[1:0]), .b(b[3:2]), .product(p2));
    vedic_multiplier_2b_full u3(.a(a[3:2]), .b(b[3:2]), .product(p3));
    assign product = {4'b0,p0} + {2'b0,p1,2'b0} + {2'b0,p2,2'b0} + {p3,4'b0};
endmodule

module vedic_multiplier_8b_full(
    input [7:0] a, input [7:0] b, output [15:0] product
);
    wire [7:0] p0,p1,p2,p3;
    vedic_multiplier_4b_full u0(.a(a[3:0]), .b(b[3:0]), .product(p0));
    vedic_multiplier_4b_full u1(.a(a[7:4]), .b(b[3:0]), .product(p1));
    vedic_multiplier_4b_full u2(.a(a[3:0]), .b(b[7:4]), .product(p2));
    vedic_multiplier_4b_full u3(.a(a[7:4]), .b(b[7:4]), .product(p3));
    assign product = {8'b0,p0} + {4'b0,p1,4'b0} + {4'b0,p2,4'b0} + {p3,8'b0};
endmodule

module vedic_multiplier_16b_full(
    input [15:0] a, input [15:0] b, output [31:0] product
);
    wire [15:0] p0,p1,p2,p3;
    vedic_multiplier_8b_full u0(.a(a[7:0]),  .b(b[7:0]),  .product(p0));
    vedic_multiplier_8b_full u1(.a(a[15:8]), .b(b[7:0]),  .product(p1));
    vedic_multiplier_8b_full u2(.a(a[7:0]),  .b(b[15:8]), .product(p2));
    vedic_multiplier_8b_full u3(.a(a[15:8]), .b(b[15:8]), .product(p3));
    assign product = {16'b0,p0} + {8'b0,p1,8'b0} + {8'b0,p2,8'b0} + {p3,16'b0};
endmodule

(* use_dsp = "no" *)
module vedic_multiplier_32b(
    input  [31:0] a,
    input  [31:0] b,
    output [63:0] product
);
    wire [31:0] p0,p1,p2,p3;
    vedic_multiplier_16b_full u0(.a(a[15:0]),  .b(b[15:0]),  .product(p0));
    vedic_multiplier_16b_full u1(.a(a[31:16]), .b(b[15:0]),  .product(p1));
    vedic_multiplier_16b_full u2(.a(a[15:0]),  .b(b[31:16]), .product(p2));
    vedic_multiplier_16b_full u3(.a(a[31:16]), .b(b[31:16]), .product(p3));
    assign product = {32'b0,p0} + {16'b0,p1,16'b0} + {16'b0,p2,16'b0} + {p3,32'b0};
endmodule
