`timescale 1ns / 1ps

module imm_gen_32b(
    input      [31:0] inst,
    input      [2:0]  ImmSel,
    output reg [31:0] imm
);

    always @(*) begin
        case (ImmSel)

            3'b000: begin // I-type
                imm = {{20{inst[31]}}, inst[31:20]};
            end

            3'b001: begin // S-type
                imm = {{20{inst[31]}}, inst[31:25], inst[11:7]};
            end

            3'b010: begin // B-type
                imm = {{19{inst[31]}},
                       inst[31],
                       inst[7],
                       inst[30:25],
                       inst[11:8],
                       1'b0};
            end

            3'b011: begin // U-type
                imm = {inst[31:12], 12'b0};
            end

            3'b100: begin // J-type
                imm = {{11{inst[31]}},
                       inst[31],
                       inst[19:12],
                       inst[20],
                       inst[30:21],
                       1'b0};
            end

            default: begin
                imm = 32'b0;
            end

        endcase
    end

endmodule
