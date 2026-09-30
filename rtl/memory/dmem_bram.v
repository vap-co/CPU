`timescale 1ns / 1ps

// Synchronous-read, byte-write data memory intended for Xilinx BRAM inference.
// Default 2048 x 32 = 64 Kibit = 8 KiB logical data storage.
module dmem_bram #(
    parameter ADDR_WIDTH = 11,
    parameter INIT_FILE = "data.mem"
)(
    input                   clk,
    input                   we,
    input  [3:0]            wstrb,
    input  [ADDR_WIDTH-1:0] addr,
    input  [31:0]           wdata,
    output reg [31:0]       rdata
);
    localparam DEPTH = (1 << ADDR_WIDTH);
    (* ram_style = "block" *) reg [31:0] mem [0:DEPTH-1];
    integer i;

    initial begin
        for (i = 0; i < DEPTH; i = i + 1)
            mem[i] = 32'b0;
        $readmemh(INIT_FILE, mem);
    end

    always @(posedge clk) begin
        rdata <= mem[addr];
        if (we) begin
            if (wstrb[0]) mem[addr][7:0]   <= wdata[7:0];
            if (wstrb[1]) mem[addr][15:8]  <= wdata[15:8];
            if (wstrb[2]) mem[addr][23:16] <= wdata[23:16];
            if (wstrb[3]) mem[addr][31:24] <= wdata[31:24];
        end
    end
endmodule
