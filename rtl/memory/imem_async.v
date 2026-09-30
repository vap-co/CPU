`timescale 1ns / 1ps

// Asynchronous instruction read.
module imem_async #(
    parameter ADDR_WIDTH = 11,
    parameter INIT_FILE = "program.mem"
)(
    input  [ADDR_WIDTH-1:0] addr,
    output [31:0] data_out
);
    localparam DEPTH = (1 << ADDR_WIDTH);
    (* ram_style = "distributed" *) reg [31:0] mem [0:DEPTH-1];
    integer i;
    assign data_out = mem[addr];

    initial begin
        for (i = 0; i < DEPTH; i = i + 1)
            mem[i] = 32'h00000013; // NOP = ADDI x0,x0,0
        $readmemh(INIT_FILE, mem);
    end
endmodule
