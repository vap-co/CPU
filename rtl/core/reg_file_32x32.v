`timescale 1ns / 1ps

module reg_file_32x32(
    input         clk,
    input         RegWEn,
    input  [4:0]  rs1,
    input  [4:0]  rs2,
    input  [4:0]  rd,
    input  [31:0] dataW,
    output [31:0] dataR1,
    output [31:0] dataR2
);

    reg [31:0] registers [0:31];

    assign dataR1 = (rs1 == 5'd0) ? 32'b0 : registers[rs1];
    assign dataR2 = (rs2 == 5'd0) ? 32'b0 : registers[rs2];

    always @(posedge clk) begin
        if (RegWEn && (rd != 5'd0)) begin
            registers[rd] <= dataW;
        end
    end

endmodule
