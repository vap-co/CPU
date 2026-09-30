`timescale 1ns / 1ps
module adder_tb;
    reg [31:0] a,b;
    reg cin;
    wire [31:0] s0,s1,s2;
    wire c0,c1,c2;
    integer i, errors;
    reg [32:0] expected;

    cpu_adder_32b #(.ADDER_TYPE(0)) rca (.a(a),.b(b),.cin(cin),.sum(s0),.cout(c0));
    cpu_adder_32b #(.ADDER_TYPE(1)) csla(.a(a),.b(b),.cin(cin),.sum(s1),.cout(c1));
    cpu_adder_32b #(.ADDER_TYPE(2)) ksa (.a(a),.b(b),.cin(cin),.sum(s2),.cout(c2));

    task check;
        input [31:0] aa,bb; input cc;
        begin
            a=aa; b=bb; cin=cc; #1;
            expected={1'b0,aa}+{1'b0,bb}+cc;
            if ({c0,s0} !== expected) begin $display("RCA FAIL %h %h %b",aa,bb,cc); errors=errors+1; end
            if ({c1,s1} !== expected) begin $display("CSLA FAIL %h %h %b",aa,bb,cc); errors=errors+1; end
            if ({c2,s2} !== expected) begin $display("KSA FAIL %h %h %b",aa,bb,cc); errors=errors+1; end
        end
    endtask

    initial begin
        errors=0;
        check(0,0,0); check(32'hffffffff,1,0); check(32'h7fffffff,1,0);
        check(32'h12345678,32'h9abcdef0,1);
        for(i=0;i<200;i=i+1) check($random,$random,$random);
        if(errors==0) $display("ADDER_TB PASS"); else $display("ADDER_TB FAIL errors=%0d",errors);
        $finish;
    end
endmodule
