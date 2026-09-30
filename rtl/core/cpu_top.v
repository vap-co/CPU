`timescale 1ns / 1ps

// Top-level selectable implementation.
// MEMORY_MODE = 0 : asynchronous legacy-style memories
// MEMORY_MODE = 1 : synchronous BRAM-oriented memories
// ADDER_TYPE  = 0/1/2 : RCA / CSLA / KSA
// MULT_TYPE   = 0/1/2 : Array / Wallace / Vedic
module cpu_top #(
    parameter ADDER_TYPE = 0,
    parameter MULT_TYPE = 0,
    parameter MEMORY_MODE = 1,
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
    output         halted
);
    generate
        if (MEMORY_MODE == 0) begin : GEN_ASYNC
            cpu_core_async #(
                .ADDER_TYPE(ADDER_TYPE), .MULT_TYPE(MULT_TYPE),
                .IMEM_ADDR_WIDTH(IMEM_ADDR_WIDTH), .DMEM_ADDR_WIDTH(DMEM_ADDR_WIDTH),
                .PROGRAM_FILE(PROGRAM_FILE), .DATA_FILE(DATA_FILE)
            ) u_core(
                .clk(clk), .rst(rst), .debug_pc(debug_pc), .debug_alu_out(debug_alu_out),
                .debug_inst(debug_inst), .debug_state(debug_state), .halted(halted)
            );
        end else begin : GEN_BRAM
            cpu_core_bram #(
                .ADDER_TYPE(ADDER_TYPE), .MULT_TYPE(MULT_TYPE),
                .IMEM_ADDR_WIDTH(IMEM_ADDR_WIDTH), .DMEM_ADDR_WIDTH(DMEM_ADDR_WIDTH),
                .PROGRAM_FILE(PROGRAM_FILE), .DATA_FILE(DATA_FILE)
            ) u_core(
                .clk(clk), .rst(rst), .debug_pc(debug_pc), .debug_alu_out(debug_alu_out),
                .debug_inst(debug_inst), .debug_state(debug_state), .halted(halted)
            );
        end
    endgenerate
endmodule
