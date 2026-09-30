`timescale 1ns / 1ps

// Synchronous instruction memory intended for Xilinx 7-series BRAM inference.
// Default 2048 x 32 = 64 Kibit = 8 KiB logical instruction storage.
module imem_bram #(
    parameter ADDR_WIDTH = 11,
    parameter INIT_FILE = "program.mem"
)(
    input                   clk,
    input  [ADDR_WIDTH-1:0] addr,
    output reg [31:0]       data_out
);
    localparam DEPTH = (1 << ADDR_WIDTH);
    (* ram_style = "block" *) reg [31:0] mem [0:DEPTH-1];
    integer i;

    initial begin
        for (i = 0; i < DEPTH; i = i + 1)
            mem[i] = 32'h00000013;
        $readmemh(INIT_FILE, mem);
    end

    always @(posedge clk) begin
        data_out <= mem[addr];
    end
endmodule
