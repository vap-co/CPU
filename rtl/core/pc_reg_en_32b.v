`timescale 1ns / 1ps
module pc_reg_en_32b(
    input clk,
    input rst,
    input en,
    input [31:0] pc_next,
    output reg [31:0] pc
);
    always @(posedge clk or posedge rst) begin
        if (rst) pc <= 32'b0;
        else if (en) pc <= pc_next;
    end
endmodule
