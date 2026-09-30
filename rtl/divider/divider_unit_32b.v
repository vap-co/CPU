`timescale 1ns / 1ps

// Iterative 32-cycle RV32M divider/remainder unit.
// funct3: 100=DIV, 101=DIVU, 110=REM, 111=REMU
module divider_unit_32b(
    input         clk,
    input         rst,
    input         start,
    input  [2:0]  funct3,
    input  [31:0] dividend,
    input  [31:0] divisor,
    output reg    busy,
    output reg    done,
    output reg [31:0] result
);
    reg [31:0] divisor_mag;
    reg [31:0] quotient_work;
    reg [31:0] remainder_work;
    reg [5:0]  count;
    reg        quotient_negative;
    reg        remainder_negative;
    reg        want_remainder;

    wire signed_op = (funct3 == 3'b100) || (funct3 == 3'b110);
    wire want_rem_in = (funct3 == 3'b110) || (funct3 == 3'b111);
    wire dividend_neg_in = signed_op && dividend[31];
    wire divisor_neg_in  = signed_op && divisor[31];
    wire [31:0] dividend_mag_in = dividend_neg_in ? (~dividend + 32'd1) : dividend;
    wire [31:0] divisor_mag_in  = divisor_neg_in  ? (~divisor  + 32'd1) : divisor;

    wire [32:0] shifted_remainder = {remainder_work, quotient_work[31]};
    wire        can_subtract = shifted_remainder >= {1'b0, divisor_mag};
    wire [32:0] remainder_after_sub = can_subtract ?
                                             (shifted_remainder - {1'b0, divisor_mag}) :
                                              shifted_remainder;
    wire [31:0] quotient_next = {quotient_work[30:0], can_subtract};
    wire [31:0] remainder_next = remainder_after_sub[31:0];

    wire [31:0] quotient_signed_final = quotient_negative ? (~quotient_next + 32'd1) : quotient_next;
    wire [31:0] remainder_signed_final = remainder_negative ? (~remainder_next + 32'd1) : remainder_next;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            busy               <= 1'b0;
            done               <= 1'b0;
            result             <= 32'b0;
            divisor_mag        <= 32'b0;
            quotient_work      <= 32'b0;
            remainder_work     <= 32'b0;
            count              <= 6'd0;
            quotient_negative  <= 1'b0;
            remainder_negative <= 1'b0;
            want_remainder     <= 1'b0;
        end else begin
            done <= 1'b0;

            if (start && !busy) begin
                // RISC-V defined divide-by-zero behavior.
                if (divisor == 32'b0) begin
                    result <= want_rem_in ? dividend : 32'hFFFF_FFFF;
                    busy   <= 1'b0;
                    done   <= 1'b1;
                end
                // Signed overflow: INT_MIN / -1.
                else if (signed_op && (dividend == 32'h8000_0000) && (divisor == 32'hFFFF_FFFF)) begin
                    result <= want_rem_in ? 32'b0 : 32'h8000_0000;
                    busy   <= 1'b0;
                    done   <= 1'b1;
                end else begin
                    divisor_mag        <= divisor_mag_in;
                    quotient_work      <= dividend_mag_in;
                    remainder_work     <= 32'b0;
                    count              <= 6'd0;
                    quotient_negative  <= dividend_neg_in ^ divisor_neg_in;
                    remainder_negative <= dividend_neg_in;
                    want_remainder     <= want_rem_in;
                    busy               <= 1'b1;
                end
            end else if (busy) begin
                quotient_work  <= quotient_next;
                remainder_work <= remainder_next;

                if (count == 6'd31) begin
                    busy   <= 1'b0;
                    done   <= 1'b1;
                    result <= want_remainder ? remainder_signed_final : quotient_signed_final;
                end else begin
                    count <= count + 6'd1;
                end
            end
        end
    end
endmodule
