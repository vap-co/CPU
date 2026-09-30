`timescale 1ns / 1ps
module divider_tb;
    reg clk=0,rst=1,start=0;
    reg [2:0] f3;
    reg [31:0] a,b;
    wire busy,done;
    wire [31:0] result;
    integer errors;
    divider_unit_32b dut(.clk(clk),.rst(rst),.start(start),.funct3(f3),.dividend(a),.divisor(b),.busy(busy),.done(done),.result(result));
    always #5 clk=~clk;

    task run_case;
        input [31:0] aa,bb; input [2:0] ff; input [31:0] exp;
        integer timeout;
        begin
            @(negedge clk); a=aa;b=bb;f3=ff;start=1;
            @(negedge clk); start=0;
            timeout=0;
            while(!done && timeout<40) begin @(negedge clk); timeout=timeout+1; end
            if(result!==exp) begin $display("DIV FAIL a=%h b=%h f3=%b exp=%h got=%h",aa,bb,ff,exp,result); errors=errors+1; end
        end
    endtask

    initial begin
        errors=0; #15; rst=0;
        run_case(10,3,3'b100,3); run_case(10,3,3'b101,3); run_case(10,3,3'b110,1); run_case(10,3,3'b111,1);
        run_case(32'hfffffff6,3,3'b100,32'hfffffffd); // -10 / 3 = -3
        run_case(32'hfffffff6,3,3'b110,32'hffffffff); // -10 % 3 = -1
        run_case(32'h80000000,32'hffffffff,3'b100,32'h80000000);
        run_case(5,0,3'b100,32'hffffffff); run_case(5,0,3'b110,5);
        if(errors==0) $display("DIVIDER_TB PASS"); else $display("DIVIDER_TB FAIL errors=%0d",errors);
        $finish;
    end
endmodule
