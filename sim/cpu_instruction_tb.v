`timescale 1ns / 1ps
module cpu_instruction_tb;
    reg clk=0,rst=1;
    wire h_async,h_bram;
    wire [31:0] pca,pcb,alua,alub,ia,ib;
    wire [3:0] sa,sb;
    integer timeout,errors;

    cpu_top #(.ADDER_TYPE(2),.MULT_TYPE(2),.MEMORY_MODE(0),.PROGRAM_FILE("program.mem")) dut_async(
        .clk(clk),.rst(rst),.debug_pc(pca),.debug_alu_out(alua),.debug_inst(ia),.debug_state(sa),.halted(h_async));
    cpu_top #(.ADDER_TYPE(2),.MULT_TYPE(2),.MEMORY_MODE(1),.PROGRAM_FILE("program.mem")) dut_bram(
        .clk(clk),.rst(rst),.debug_pc(pcb),.debug_alu_out(alub),.debug_inst(ib),.debug_state(sb),.halted(h_bram));
    always #5 clk=~clk;

`define CHECK_ASYNC(IDX,EXP) if(dut_async.GEN_ASYNC.u_core.reg_file.registers[IDX] !== EXP) begin \
    $display("ASYNC x%0d exp=%h got=%h",IDX,EXP,dut_async.GEN_ASYNC.u_core.reg_file.registers[IDX]); errors=errors+1; end
`define CHECK_BRAM(IDX,EXP) if(dut_bram.GEN_BRAM.u_core.reg_file.registers[IDX] !== EXP) begin \
    $display("BRAM x%0d exp=%h got=%h",IDX,EXP,dut_bram.GEN_BRAM.u_core.reg_file.registers[IDX]); errors=errors+1; end

    task check_expected;
        begin
            `CHECK_ASYNC(1,32'h0000000a) `CHECK_BRAM(1,32'h0000000a)
            `CHECK_ASYNC(3,32'h0000000d) `CHECK_BRAM(3,32'h0000000d)
            `CHECK_ASYNC(4,32'h00000007) `CHECK_BRAM(4,32'h00000007)
            `CHECK_ASYNC(5,32'h00000005) `CHECK_BRAM(5,32'h00000005)
            `CHECK_ASYNC(8,32'h00000008) `CHECK_BRAM(8,32'h00000008)
            `CHECK_ASYNC(14,32'h0000001e) `CHECK_BRAM(14,32'h0000001e)
            `CHECK_ASYNC(15,32'hffffffff) `CHECK_BRAM(15,32'hffffffff)
            `CHECK_ASYNC(16,32'hffffffff) `CHECK_BRAM(16,32'hffffffff)
            `CHECK_ASYNC(17,32'h00000002) `CHECK_BRAM(17,32'h00000002)
            `CHECK_ASYNC(18,32'h00000003) `CHECK_BRAM(18,32'h00000003)
            `CHECK_ASYNC(19,32'h00000003) `CHECK_BRAM(19,32'h00000003)
            `CHECK_ASYNC(20,32'h00000001) `CHECK_BRAM(20,32'h00000001)
            `CHECK_ASYNC(21,32'h00000001) `CHECK_BRAM(21,32'h00000001)
            `CHECK_ASYNC(23,32'h0000000d) `CHECK_BRAM(23,32'h0000000d)
            `CHECK_ASYNC(24,32'h0000000a) `CHECK_BRAM(24,32'h0000000a)
            `CHECK_ASYNC(25,32'h0000000a) `CHECK_BRAM(25,32'h0000000a)
            `CHECK_ASYNC(27,32'hfffffffe) `CHECK_BRAM(27,32'hfffffffe)
            `CHECK_ASYNC(28,32'h0000fffe) `CHECK_BRAM(28,32'h0000fffe)
            `CHECK_ASYNC(29,32'h00000004) `CHECK_BRAM(29,32'h00000004)
            `CHECK_ASYNC(30,32'h00000002) `CHECK_BRAM(30,32'h00000002)
            `CHECK_ASYNC(31,32'h000000d0) `CHECK_BRAM(31,32'h000000d0)
        end
    endtask

    initial begin
        errors=0; #20; rst=0; timeout=0;
        while((!h_async || !h_bram) && timeout<2000) begin @(posedge clk); timeout=timeout+1; end
        if(!h_async || !h_bram) begin $display("CPU TIMEOUT async=%b bram=%b pca=%h pcb=%h",h_async,h_bram,pca,pcb); errors=errors+1; end
        check_expected;
        if(errors==0) $display("CPU_INSTRUCTION_TB PASS (async + BRAM)"); else $display("CPU_INSTRUCTION_TB FAIL errors=%0d",errors);
        $finish;
    end
endmodule
