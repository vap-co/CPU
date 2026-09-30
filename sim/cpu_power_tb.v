`timescale 1ns / 1ps

module cpu_power_tb;
    parameter ADDER_TYPE = 0;
    parameter MULT_TYPE = 0;
    parameter MEMORY_MODE = 1;
    parameter PROGRAM_FILE = "program.mem";
    parameter DATA_FILE = "data.mem";
    parameter EXPECTED_CHECKSUM = -1;

    reg clk = 0;
    reg rst = 1;
    wire halted;

    cpu_top #(
        .ADDER_TYPE(ADDER_TYPE),
        .MULT_TYPE(MULT_TYPE),
        .MEMORY_MODE(MEMORY_MODE),
        .PROGRAM_FILE(PROGRAM_FILE),
        .DATA_FILE(DATA_FILE)
    ) dut (
        .clk(clk),
        .rst(rst),
        .debug_pc(),
        .debug_alu_out(),
        .debug_inst(),
        .debug_state(),
        .halted(halted)
    );

    always #15 clk = ~clk; // 30 ns period -> 33.333 MHz

    integer timeout;
    initial begin
        timeout = 0;
        rst = 1;
        #35;
        rst = 0;
        
        while(!halted && timeout < 500000) begin 
            @(posedge clk); 
            timeout = timeout + 1; 
        end
        
        if (timeout >= 500000) begin
            $display("TIMEOUT waiting for halted");
            $fatal(1, "Benchmark timed out");
        end else begin
            $display("HALTED asserted at time %0t", $time);
        end
        
        repeat(5) @(posedge clk);
        $display("Simulation Finished Successfully.");
        $display("Benchmark Checksum (a0/x10): %d", dut.GEN_BRAM.u_core.reg_file.registers[10]);
        if (EXPECTED_CHECKSUM >= 0 &&
            dut.GEN_BRAM.u_core.reg_file.registers[10] !== EXPECTED_CHECKSUM)
            $fatal(1, "Benchmark checksum mismatch");
        $display("BENCHMARK PASS");
        $stop;
    end
endmodule
