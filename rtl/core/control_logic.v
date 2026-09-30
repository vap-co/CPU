`timescale 1ns / 1ps

// RV32IM decoder shared by both memory modes.
module control_logic(
    input      [31:0] inst,
    input             BrEq,
    input             BrLT,
    output reg        PCSel,
    output reg [2:0]  ImmSel,
    output reg        RegWEn,
    output reg        BrUn,
    output reg        Asel,
    output reg        Bsel,
    output reg [3:0]  ALUSel,
    output reg        MemRead,
    output reg        MemWrite,
    output reg [1:0]  WBSel,
    output reg [2:0]  MemFunct3,
    output reg [2:0]  MFunct3,
    output reg        IsMul,
    output reg        IsDiv,
    output reg        Jalr,
    output reg        Halt,
    output reg        Illegal
);
    wire [6:0] opcode = inst[6:0];
    wire [2:0] funct3 = inst[14:12];
    wire [6:0] funct7 = inst[31:25];

    localparam OP_LOAD      = 7'b0000011;
    localparam OP_MISC_MEM  = 7'b0001111;
    localparam OP_I_ALU     = 7'b0010011;
    localparam OP_AUIPC     = 7'b0010111;
    localparam OP_STORE     = 7'b0100011;
    localparam OP_R_TYPE    = 7'b0110011;
    localparam OP_LUI       = 7'b0110111;
    localparam OP_BRANCH    = 7'b1100011;
    localparam OP_JALR      = 7'b1100111;
    localparam OP_JAL       = 7'b1101111;
    localparam OP_SYSTEM    = 7'b1110011;

    localparam ALU_ADD    = 4'b0000;
    localparam ALU_SUB    = 4'b0001;
    localparam ALU_AND    = 4'b0010;
    localparam ALU_OR     = 4'b0011;
    localparam ALU_XOR    = 4'b0100;
    localparam ALU_SLL    = 4'b0101;
    localparam ALU_SRL    = 4'b0110;
    localparam ALU_SRA    = 4'b0111;
    localparam ALU_SLT    = 4'b1000;
    localparam ALU_SLTU   = 4'b1001;
    localparam ALU_PASS_B = 4'b1010;
    localparam ALU_MUL    = 4'b1011;

    always @(*) begin
        PCSel     = 1'b0;
        ImmSel    = 3'b000;
        RegWEn    = 1'b0;
        BrUn      = 1'b0;
        Asel      = 1'b0;
        Bsel      = 1'b0;
        ALUSel    = ALU_ADD;
        MemRead   = 1'b0;
        MemWrite  = 1'b0;
        WBSel     = 2'b01;
        MemFunct3 = funct3;
        MFunct3   = funct3;
        IsMul     = 1'b0;
        IsDiv     = 1'b0;
        Jalr      = 1'b0;
        Halt      = 1'b0;
        Illegal   = 1'b0;

        case (opcode)
            OP_R_TYPE: begin
                RegWEn = 1'b1;
                if (funct7 == 7'b0000001) begin
                    MFunct3 = funct3;
                    if (funct3 <= 3'b011) begin
                        IsMul  = 1'b1;
                        ALUSel = ALU_MUL;
                    end else begin
                        IsDiv  = 1'b1;
                    end
                end else begin
                    case (funct3)
                        3'b000: begin
                            if (funct7 == 7'b0000000) ALUSel = ALU_ADD;
                            else if (funct7 == 7'b0100000) ALUSel = ALU_SUB;
                            else Illegal = 1'b1;
                        end
                        3'b001: begin ALUSel = ALU_SLL;  if (funct7 != 7'b0000000) Illegal = 1'b1; end
                        3'b010: begin ALUSel = ALU_SLT;  if (funct7 != 7'b0000000) Illegal = 1'b1; end
                        3'b011: begin ALUSel = ALU_SLTU; if (funct7 != 7'b0000000) Illegal = 1'b1; end
                        3'b100: begin ALUSel = ALU_XOR;  if (funct7 != 7'b0000000) Illegal = 1'b1; end
                        3'b101: begin
                            if (funct7 == 7'b0000000) ALUSel = ALU_SRL;
                            else if (funct7 == 7'b0100000) ALUSel = ALU_SRA;
                            else Illegal = 1'b1;
                        end
                        3'b110: begin ALUSel = ALU_OR;   if (funct7 != 7'b0000000) Illegal = 1'b1; end
                        3'b111: begin ALUSel = ALU_AND;  if (funct7 != 7'b0000000) Illegal = 1'b1; end
                        default: Illegal = 1'b1;
                    endcase
                end
            end

            OP_I_ALU: begin
                RegWEn = 1'b1;
                ImmSel = 3'b000;
                Bsel   = 1'b1;
                case (funct3)
                    3'b000: ALUSel = ALU_ADD;  // ADDI
                    3'b010: ALUSel = ALU_SLT;  // SLTI
                    3'b011: ALUSel = ALU_SLTU; // SLTIU
                    3'b100: ALUSel = ALU_XOR;  // XORI
                    3'b110: ALUSel = ALU_OR;   // ORI
                    3'b111: ALUSel = ALU_AND;  // ANDI
                    3'b001: begin
                        ALUSel = ALU_SLL;
                        if (inst[31:25] != 7'b0000000) Illegal = 1'b1;
                    end
                    3'b101: begin
                        if (inst[31:25] == 7'b0000000) ALUSel = ALU_SRL;
                        else if (inst[31:25] == 7'b0100000) ALUSel = ALU_SRA;
                        else Illegal = 1'b1;
                    end
                    default: Illegal = 1'b1;
                endcase
            end

            OP_LOAD: begin
                RegWEn    = 1'b1;
                ImmSel    = 3'b000;
                Bsel      = 1'b1;
                ALUSel    = ALU_ADD;
                MemRead   = 1'b1;
                WBSel     = 2'b00;
                MemFunct3 = funct3;
                if (!((funct3 == 3'b000) || (funct3 == 3'b001) || (funct3 == 3'b010) ||
                      (funct3 == 3'b100) || (funct3 == 3'b101))) Illegal = 1'b1;
            end

            OP_STORE: begin
                ImmSel    = 3'b001;
                Bsel      = 1'b1;
                ALUSel    = ALU_ADD;
                MemWrite  = 1'b1;
                MemFunct3 = funct3;
                if (!((funct3 == 3'b000) || (funct3 == 3'b001) || (funct3 == 3'b010))) Illegal = 1'b1;
            end

            OP_BRANCH: begin
                ImmSel = 3'b010;
                Asel   = 1'b1;
                Bsel   = 1'b1;
                ALUSel = ALU_ADD;
                case (funct3)
                    3'b000: PCSel = BrEq;   // BEQ
                    3'b001: PCSel = ~BrEq;  // BNE
                    3'b100: PCSel = BrLT;   // BLT
                    3'b101: PCSel = ~BrLT;  // BGE
                    3'b110: begin BrUn=1'b1; PCSel=BrLT;  end // BLTU
                    3'b111: begin BrUn=1'b1; PCSel=~BrLT; end // BGEU
                    default: Illegal = 1'b1;
                endcase
            end

            OP_JAL: begin
                RegWEn = 1'b1;
                ImmSel = 3'b100;
                Asel   = 1'b1;
                Bsel   = 1'b1;
                ALUSel = ALU_ADD;
                PCSel  = 1'b1;
                WBSel  = 2'b10;
            end

            OP_JALR: begin
                RegWEn = 1'b1;
                ImmSel = 3'b000;
                Bsel   = 1'b1;
                ALUSel = ALU_ADD;
                PCSel  = 1'b1;
                WBSel  = 2'b10;
                Jalr   = 1'b1;
                if (funct3 != 3'b000) Illegal = 1'b1;
            end

            OP_LUI: begin
                RegWEn = 1'b1;
                ImmSel = 3'b011;
                Bsel   = 1'b1;
                ALUSel = ALU_PASS_B;
                WBSel  = 2'b01;
            end

            OP_AUIPC: begin
                RegWEn = 1'b1;
                ImmSel = 3'b011;
                Asel   = 1'b1;
                Bsel   = 1'b1;
                ALUSel = ALU_ADD;
                WBSel  = 2'b01;
            end

            OP_MISC_MEM: begin
                // FENCE is a no-op; this core has no outstanding memory requests.
                if (funct3 != 3'b000) Illegal = 1'b1;
            end

            OP_SYSTEM: begin
                // ECALL and EBREAK halt the test core; traps are not implemented.
                if ((funct3 == 3'b000) && ((inst[31:20] == 12'h000) || (inst[31:20] == 12'h001)))
                    Halt = 1'b1;
                else
                    Illegal = 1'b1;
            end

            default: Illegal = 1'b1;
        endcase

        if (Illegal) begin
            RegWEn   = 1'b0;
            MemRead  = 1'b0;
            MemWrite = 1'b0;
            IsMul    = 1'b0;
            IsDiv    = 1'b0;
            PCSel    = 1'b0;
        end
    end
endmodule
