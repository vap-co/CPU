`timescale 1ns / 1ps
module cpu_9config_tb;
    reg clk=0,rst=1;
    wire h00,h01,h02,h10,h11,h12,h20,h21,h22;
    wire [8:0] halted = {h22,h21,h20,h12,h11,h10,h02,h01,h00};
    integer timeout,errors;

    cpu_top #(.ADDER_TYPE(0),.MULT_TYPE(0),.MEMORY_MODE(0),.PROGRAM_FILE("program.mem")) c00(.clk(clk),.rst(rst),.debug_pc(),.debug_alu_out(),.debug_inst(),.debug_state(),.halted(h00));
    cpu_top #(.ADDER_TYPE(0),.MULT_TYPE(1),.MEMORY_MODE(0),.PROGRAM_FILE("program.mem")) c01(.clk(clk),.rst(rst),.debug_pc(),.debug_alu_out(),.debug_inst(),.debug_state(),.halted(h01));
    cpu_top #(.ADDER_TYPE(0),.MULT_TYPE(2),.MEMORY_MODE(0),.PROGRAM_FILE("program.mem")) c02(.clk(clk),.rst(rst),.debug_pc(),.debug_alu_out(),.debug_inst(),.debug_state(),.halted(h02));
    cpu_top #(.ADDER_TYPE(1),.MULT_TYPE(0),.MEMORY_MODE(0),.PROGRAM_FILE("program.mem")) c10(.clk(clk),.rst(rst),.debug_pc(),.debug_alu_out(),.debug_inst(),.debug_state(),.halted(h10));
    cpu_top #(.ADDER_TYPE(1),.MULT_TYPE(1),.MEMORY_MODE(0),.PROGRAM_FILE("program.mem")) c11(.clk(clk),.rst(rst),.debug_pc(),.debug_alu_out(),.debug_inst(),.debug_state(),.halted(h11));
    cpu_top #(.ADDER_TYPE(1),.MULT_TYPE(2),.MEMORY_MODE(0),.PROGRAM_FILE("program.mem")) c12(.clk(clk),.rst(rst),.debug_pc(),.debug_alu_out(),.debug_inst(),.debug_state(),.halted(h12));
    cpu_top #(.ADDER_TYPE(2),.MULT_TYPE(0),.MEMORY_MODE(0),.PROGRAM_FILE("program.mem")) c20(.clk(clk),.rst(rst),.debug_pc(),.debug_alu_out(),.debug_inst(),.debug_state(),.halted(h20));
    cpu_top #(.ADDER_TYPE(2),.MULT_TYPE(1),.MEMORY_MODE(0),.PROGRAM_FILE("program.mem")) c21(.clk(clk),.rst(rst),.debug_pc(),.debug_alu_out(),.debug_inst(),.debug_state(),.halted(h21));
    cpu_top #(.ADDER_TYPE(2),.MULT_TYPE(2),.MEMORY_MODE(0),.PROGRAM_FILE("program.mem")) c22(.clk(clk),.rst(rst),.debug_pc(),.debug_alu_out(),.debug_inst(),.debug_state(),.halted(h22));
    always #5 clk=~clk;

`define CMP(CORE,IDX) if(CORE.GEN_ASYNC.u_core.reg_file.registers[IDX] !== c00.GEN_ASYNC.u_core.reg_file.registers[IDX]) begin \
    $display("9CFG mismatch x%0d ref=%h got=%h",IDX,c00.GEN_ASYNC.u_core.reg_file.registers[IDX],CORE.GEN_ASYNC.u_core.reg_file.registers[IDX]); errors=errors+1; end

    task compare_all;
        begin
            `CMP(c01,14) `CMP(c02,14) `CMP(c10,14) `CMP(c11,14) `CMP(c12,14) `CMP(c20,14) `CMP(c21,14) `CMP(c22,14)
            `CMP(c01,15) `CMP(c02,15) `CMP(c10,15) `CMP(c11,15) `CMP(c12,15) `CMP(c20,15) `CMP(c21,15) `CMP(c22,15)
            `CMP(c01,16) `CMP(c02,16) `CMP(c10,16) `CMP(c11,16) `CMP(c12,16) `CMP(c20,16) `CMP(c21,16) `CMP(c22,16)
            `CMP(c01,17) `CMP(c02,17) `CMP(c10,17) `CMP(c11,17) `CMP(c12,17) `CMP(c20,17) `CMP(c21,17) `CMP(c22,17)
            `CMP(c01,18) `CMP(c02,18) `CMP(c10,18) `CMP(c11,18) `CMP(c12,18) `CMP(c20,18) `CMP(c21,18) `CMP(c22,18)
            `CMP(c01,23) `CMP(c02,23) `CMP(c10,23) `CMP(c11,23) `CMP(c12,23) `CMP(c20,23) `CMP(c21,23) `CMP(c22,23)
            `CMP(c01,29) `CMP(c02,29) `CMP(c10,29) `CMP(c11,29) `CMP(c12,29) `CMP(c20,29) `CMP(c21,29) `CMP(c22,29)
            `CMP(c01,31) `CMP(c02,31) `CMP(c10,31) `CMP(c11,31) `CMP(c12,31) `CMP(c20,31) `CMP(c21,31) `CMP(c22,31)
        end
    endtask

    initial begin
        errors=0; #20; rst=0; timeout=0;
        while((halted !== 9'h1ff) && timeout<1500) begin @(posedge clk); timeout=timeout+1; end
        if(halted !== 9'h1ff) begin $display("9CFG TIMEOUT halted=%b",halted); errors=errors+1; end
        compare_all;
        if(c00.GEN_ASYNC.u_core.reg_file.registers[14] !== 32'h1e) errors=errors+1;
        if(c00.GEN_ASYNC.u_core.reg_file.registers[29] !== 32'h4) errors=errors+1;
        if(errors==0) $display("CPU_9CONFIG_TB PASS"); else $display("CPU_9CONFIG_TB FAIL errors=%0d",errors);
        $finish;
    end
endmodule
