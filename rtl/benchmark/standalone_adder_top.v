`timescale 1ns / 1ps

// Input and output registers define the measured adder path.
module standalone_adder_top #(
    parameter ADDER_TYPE = 0
)(
    input         clk,
    input  [31:0] a_in,
    input  [31:0] b_in,
    input         cin_in,
    output reg [31:0] sum_out,
    output reg        cout_out
);
    reg [31:0] a_reg, b_reg;
    reg cin_reg;
    wire [31:0] sum_comb;
    wire cout_comb;

    cpu_adder_32b #(.ADDER_TYPE(ADDER_TYPE)) dut(
        .a(a_reg), .b(b_reg), .cin(cin_reg), .sum(sum_comb), .cout(cout_comb)
    );

    always @(posedge clk) begin
        a_reg    <= a_in;
        b_reg    <= b_in;
        cin_reg  <= cin_in;
        sum_out  <= sum_comb;
        cout_out <= cout_comb;
    end
endmodule
