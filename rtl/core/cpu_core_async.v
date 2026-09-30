`timescale 1ns / 1ps

// Asynchronous memory reads; DIV/REM stalls the PC until completion.
module cpu_core_async #(
    parameter ADDER_TYPE = 0,
    parameter MULT_TYPE = 0,
    parameter IMEM_ADDR_WIDTH = 11,
    parameter DMEM_ADDR_WIDTH = 11,
    parameter PROGRAM_FILE = "program.mem",
    parameter DATA_FILE = "data.mem"
)(
    input  clk,
    input  rst,
    output [31:0] debug_pc,
    output [31:0] debug_alu_out,
    output [31:0] debug_inst,
    output [3:0]  debug_state,
    output reg     halted
);
    wire [31:0] pc_out, pc_plus4, pc_next_normal;
    wire [31:0] inst;
    wire [31:0] dataR1, dataR2, dataW_normal;
    wire [31:0] imm;
    wire [31:0] alu_inA, alu_inB, alu_out;
    wire [31:0] pc_target;
    wire BrEq, BrLT;

    wire PCSel, RegWEn, BrUn, Asel, Bsel, MemRead, MemWrite, IsMul, IsDiv, Jalr, Halt, Illegal;
    wire [2:0] ImmSel, MemFunct3, MFunct3;
    wire [3:0] ALUSel;
    wire [1:0] WBSel;

    wire [31:0] dmem_rdata;
    wire [31:0] load_data;
    wire [31:0] store_wdata;
    wire [3:0]  store_wstrb;

    reg div_active;
    wire div_start = IsDiv && !div_active && !halted && !Illegal;
    wire div_busy, div_done;
    wire [31:0] div_result;

    wire normal_commit = !halted && !Illegal && !Halt && !IsDiv;
    wire div_commit = div_active && div_done && !halted;
    wire rf_we = (normal_commit && RegWEn) || (div_commit && RegWEn);
    wire [31:0] rf_wdata = div_commit ? div_result : dataW_normal;
    wire pc_en = normal_commit || div_commit;
    wire [31:0] pc_next = div_commit ? pc_plus4 : pc_next_normal;

    assign debug_pc      = pc_out;
    assign debug_alu_out = alu_out;
    assign debug_inst    = inst;
    assign debug_state   = div_active ? 4'd1 : (halted ? 4'd15 : 4'd0);

    pc_reg_en_32b pc_reg(.clk(clk), .rst(rst), .en(pc_en), .pc_next(pc_next), .pc(pc_out));
    pc_plus4_32b pc_adder(.pc(pc_out), .pc_plus4(pc_plus4));

    imem_async #(.ADDR_WIDTH(IMEM_ADDR_WIDTH), .INIT_FILE(PROGRAM_FILE)) imem(
        .addr(pc_out[IMEM_ADDR_WIDTH+1:2]), .data_out(inst)
    );

    control_logic ctrl(
        .inst(inst), .BrEq(BrEq), .BrLT(BrLT), .PCSel(PCSel), .ImmSel(ImmSel),
        .RegWEn(RegWEn), .BrUn(BrUn), .Asel(Asel), .Bsel(Bsel), .ALUSel(ALUSel),
        .MemRead(MemRead), .MemWrite(MemWrite), .WBSel(WBSel), .MemFunct3(MemFunct3),
        .MFunct3(MFunct3), .IsMul(IsMul), .IsDiv(IsDiv), .Jalr(Jalr),
        .Halt(Halt), .Illegal(Illegal)
    );

    reg_file_32x32 reg_file(
        .clk(clk), .RegWEn(rf_we), .rs1(inst[19:15]), .rs2(inst[24:20]), .rd(inst[11:7]),
        .dataW(rf_wdata), .dataR1(dataR1), .dataR2(dataR2)
    );

    imm_gen_32b imm_gen(.inst(inst), .ImmSel(ImmSel), .imm(imm));
    branch_comp_32b br_comp(.dataR1(dataR1), .dataR2(dataR2), .BrUn(BrUn), .BrEq(BrEq), .BrLT(BrLT));
    mux2_1_32b alu_mux_a(.in0(dataR1), .in1(pc_out), .sel(Asel), .out(alu_inA));
    mux2_1_32b alu_mux_b(.in0(dataR2), .in1(imm), .sel(Bsel), .out(alu_inB));

    alu_32b #(.ADDER_TYPE(ADDER_TYPE), .MULT_TYPE(MULT_TYPE)) alu(
        .A(alu_inA), .B(alu_inB), .ALUSel(ALUSel), .MFunct3(MFunct3), .alu_out(alu_out)
    );

    assign pc_target = Jalr ? {alu_out[31:1],1'b0} : alu_out;
    assign pc_next_normal = PCSel ? pc_target : pc_plus4;

    load_store_unit lsu(
        .mem_rdata(dmem_rdata), .store_data(dataR2), .addr_lsb(alu_out[1:0]), .funct3(MemFunct3),
        .load_data(load_data), .store_wdata(store_wdata), .store_wstrb(store_wstrb)
    );

    dmem_async #(.ADDR_WIDTH(DMEM_ADDR_WIDTH), .INIT_FILE(DATA_FILE)) dmem(
        .clk(clk),
        .we(normal_commit && MemWrite),
        .wstrb(store_wstrb),
        .addr(alu_out[DMEM_ADDR_WIDTH+1:2]),
        .wdata(store_wdata),
        .rdata(dmem_rdata)
    );

    mux3_1_32b wb_mux(.in0(load_data), .in1(alu_out), .in2(pc_plus4), .sel(WBSel), .out(dataW_normal));

    divider_unit_32b divider(
        .clk(clk), .rst(rst), .start(div_start), .funct3(MFunct3),
        .dividend(dataR1), .divisor(dataR2), .busy(div_busy), .done(div_done), .result(div_result)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            div_active <= 1'b0;
            halted     <= 1'b0;
        end else begin
            if (!halted) begin
                if (Halt || Illegal) begin
                    halted <= 1'b1;
                end else if (IsDiv && !div_active) begin
                    div_active <= 1'b1;
                end else if (div_active && div_done) begin
                    div_active <= 1'b0;
                end
            end
        end
    end
endmodule
