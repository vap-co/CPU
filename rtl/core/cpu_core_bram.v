`timescale 1ns / 1ps

// RV32IM core with synchronous Xilinx BRAM-oriented instruction/data memories.
// Fetch and load latency are handled explicitly by a small sequencer.
module cpu_core_bram #(
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
    localparam S_FETCH      = 4'd0;
    localparam S_FETCH_WAIT = 4'd1;
    localparam S_EXECUTE    = 4'd2;
    localparam S_LOAD_WAIT  = 4'd3;
    localparam S_DIV_WAIT   = 4'd4;
    localparam S_HALT       = 4'd15;

    reg [3:0] state;
    reg [31:0] pc;
    reg [31:0] ir;
    reg [31:0] load_addr_hold;
    reg [2:0]  load_funct_hold;

    wire [31:0] pc_plus4;
    wire [31:0] imem_rdata;
    wire [31:0] dataR1, dataR2;
    wire [31:0] imm;
    wire [31:0] alu_inA, alu_inB, alu_out;
    wire [31:0] pc_target;
    wire [31:0] pc_next_normal;
    wire BrEq, BrLT;

    wire PCSel, RegWEn, BrUn, Asel, Bsel, MemRead, MemWrite, IsMul, IsDiv, Jalr, Halt, Illegal;
    wire [2:0] ImmSel, MemFunct3, MFunct3;
    wire [3:0] ALUSel;
    wire [1:0] WBSel;

    wire [31:0] dmem_rdata;
    wire [31:0] load_data_exec, store_wdata;
    wire [3:0]  store_wstrb;
    wire [31:0] load_data_wait;
    wire [31:0] wb_exec;

    wire div_start = (state == S_EXECUTE) && IsDiv && !Illegal && !Halt;
    wire div_busy, div_done;
    wire [31:0] div_result;

    wire [31:0] dmem_addr_mux = (state == S_EXECUTE) ? alu_out : load_addr_hold;
    wire dmem_we = (state == S_EXECUTE) && MemWrite && !Illegal && !Halt;

    wire rf_we_exec = (state == S_EXECUTE) && RegWEn && !MemRead && !IsDiv && !Illegal && !Halt;
    wire rf_we_load = (state == S_LOAD_WAIT);
    wire rf_we_div  = (state == S_DIV_WAIT) && div_done;
    wire rf_we      = rf_we_exec || rf_we_load || rf_we_div;
    wire [31:0] rf_wdata = rf_we_div ? div_result : (rf_we_load ? load_data_wait : wb_exec);

    assign debug_pc      = pc;
    assign debug_alu_out = alu_out;
    assign debug_inst    = ir;
    assign debug_state   = state;

    pc_plus4_32b pc_adder(.pc(pc), .pc_plus4(pc_plus4));

    imem_bram #(.ADDR_WIDTH(IMEM_ADDR_WIDTH), .INIT_FILE(PROGRAM_FILE)) imem(
        .clk(clk), .addr(pc[IMEM_ADDR_WIDTH+1:2]), .data_out(imem_rdata)
    );

    control_logic ctrl(
        .inst(ir), .BrEq(BrEq), .BrLT(BrLT), .PCSel(PCSel), .ImmSel(ImmSel),
        .RegWEn(RegWEn), .BrUn(BrUn), .Asel(Asel), .Bsel(Bsel), .ALUSel(ALUSel),
        .MemRead(MemRead), .MemWrite(MemWrite), .WBSel(WBSel), .MemFunct3(MemFunct3),
        .MFunct3(MFunct3), .IsMul(IsMul), .IsDiv(IsDiv), .Jalr(Jalr),
        .Halt(Halt), .Illegal(Illegal)
    );

    reg_file_32x32 reg_file(
        .clk(clk), .RegWEn(rf_we), .rs1(ir[19:15]), .rs2(ir[24:20]), .rd(ir[11:7]),
        .dataW(rf_wdata), .dataR1(dataR1), .dataR2(dataR2)
    );

    imm_gen_32b imm_gen(.inst(ir), .ImmSel(ImmSel), .imm(imm));
    branch_comp_32b br_comp(.dataR1(dataR1), .dataR2(dataR2), .BrUn(BrUn), .BrEq(BrEq), .BrLT(BrLT));
    mux2_1_32b alu_mux_a(.in0(dataR1), .in1(pc), .sel(Asel), .out(alu_inA));
    mux2_1_32b alu_mux_b(.in0(dataR2), .in1(imm), .sel(Bsel), .out(alu_inB));

    alu_32b #(.ADDER_TYPE(ADDER_TYPE), .MULT_TYPE(MULT_TYPE)) alu(
        .A(alu_inA), .B(alu_inB), .ALUSel(ALUSel), .MFunct3(MFunct3), .alu_out(alu_out)
    );

    assign pc_target = Jalr ? {alu_out[31:1],1'b0} : alu_out;
    assign pc_next_normal = PCSel ? pc_target : pc_plus4;

    load_store_unit lsu_exec(
        .mem_rdata(dmem_rdata), .store_data(dataR2), .addr_lsb(alu_out[1:0]), .funct3(MemFunct3),
        .load_data(load_data_exec), .store_wdata(store_wdata), .store_wstrb(store_wstrb)
    );
    load_store_unit lsu_wait(
        .mem_rdata(dmem_rdata), .store_data(32'b0), .addr_lsb(load_addr_hold[1:0]), .funct3(load_funct_hold),
        .load_data(load_data_wait), .store_wdata(), .store_wstrb()
    );

    dmem_bram #(.ADDR_WIDTH(DMEM_ADDR_WIDTH), .INIT_FILE(DATA_FILE)) dmem(
        .clk(clk), .we(dmem_we), .wstrb(store_wstrb),
        .addr(dmem_addr_mux[DMEM_ADDR_WIDTH+1:2]), .wdata(store_wdata), .rdata(dmem_rdata)
    );

    mux3_1_32b wb_mux(.in0(load_data_exec), .in1(alu_out), .in2(pc_plus4), .sel(WBSel), .out(wb_exec));

    divider_unit_32b divider(
        .clk(clk), .rst(rst), .start(div_start), .funct3(MFunct3),
        .dividend(dataR1), .divisor(dataR2), .busy(div_busy), .done(div_done), .result(div_result)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state           <= S_FETCH;
            pc              <= 32'b0;
            ir              <= 32'h00000013;
            load_addr_hold  <= 32'b0;
            load_funct_hold <= 3'b010;
            halted          <= 1'b0;
        end else begin
            case (state)
                S_FETCH: begin
                    state <= S_FETCH_WAIT;
                end

                S_FETCH_WAIT: begin
                    ir    <= imem_rdata;
                    state <= S_EXECUTE;
                end

                S_EXECUTE: begin
                    if (Halt || Illegal) begin
                        halted <= 1'b1;
                        state  <= S_HALT;
                    end else if (IsDiv) begin
                        state <= S_DIV_WAIT;
                    end else if (MemRead) begin
                        load_addr_hold  <= alu_out;
                        load_funct_hold <= MemFunct3;
                        state <= S_LOAD_WAIT;
                    end else begin
                        pc    <= pc_next_normal;
                        state <= S_FETCH;
                    end
                end

                S_LOAD_WAIT: begin
                    pc    <= pc_plus4;
                    state <= S_FETCH;
                end

                S_DIV_WAIT: begin
                    if (div_done) begin
                        pc    <= pc_plus4;
                        state <= S_FETCH;
                    end
                end

                default: begin
                    halted <= 1'b1;
                    state  <= S_HALT;
                end
            endcase
        end
    end
endmodule
