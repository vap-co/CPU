`timescale 1ns / 1ps

module alu_32b #(
    parameter ADDER_TYPE = 0,
    parameter MULT_TYPE  = 0
)(
    input      [31:0] A,
    input      [31:0] B,
    input      [3:0]  ALUSel,
    input      [2:0]  MFunct3,
    output reg [31:0] alu_out
);
    wire [31:0] b_mux;
    wire        cin_mux;
    wire [31:0] adder_result;
    wire [31:0] mul_result;

    assign b_mux   = (ALUSel == 4'b0001) ? ~B   : B;
    assign cin_mux = (ALUSel == 4'b0001) ? 1'b1 : 1'b0;

    (* keep_hierarchy = "yes" *) cpu_adder_32b #(.ADDER_TYPE(ADDER_TYPE)) u_adder(
        .a(A), .b(b_mux), .cin(cin_mux), .sum(adder_result), .cout()
    );

    (* keep_hierarchy = "yes" *) mul_unit_32b #(.MULT_TYPE(MULT_TYPE)) u_mul(
        .a(A), .b(B), .funct3(MFunct3), .result(mul_result)
    );

    always @(*) begin
        case (ALUSel)
            4'b0000: alu_out = adder_result;
            4'b0001: alu_out = adder_result;
            4'b0010: alu_out = A & B;
            4'b0011: alu_out = A | B;
            4'b0100: alu_out = A ^ B;
            4'b0101: alu_out = A << B[4:0];
            4'b0110: alu_out = A >> B[4:0];
            4'b0111: alu_out = $signed(A) >>> B[4:0];
            4'b1000: alu_out = ($signed(A) < $signed(B)) ? 32'd1 : 32'd0;
            4'b1001: alu_out = (A < B) ? 32'd1 : 32'd0;
            4'b1010: alu_out = B;
            4'b1011: alu_out = mul_result;
            default: alu_out = 32'b0;
        endcase
    end
endmodule
