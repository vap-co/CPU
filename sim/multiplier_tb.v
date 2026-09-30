`timescale 1ns / 1ps

module multiplier_tb;
    reg  [31:0] a, b;
    reg  [2:0]  f3;

    wire [63:0] p_array;
    wire [63:0] p_wallace;
    wire [63:0] p_vedic;

    wire [31:0] r_array;
    wire [31:0] r_wallace;
    wire [31:0] r_vedic;

    integer i;
    integer errors;

    reg [63:0] expected_u;
    reg [31:0] expected_r;
    reg signed [63:0] sa64;
    reg signed [63:0] sb64;
    reg signed [63:0] expected_s;

    cpu_multiplier_32b #(.MULT_TYPE(0)) u_array (
        .a(a), .b(b), .product(p_array)
    );

    cpu_multiplier_32b #(.MULT_TYPE(1)) u_wallace (
        .a(a), .b(b), .product(p_wallace)
    );

    cpu_multiplier_32b #(.MULT_TYPE(2)) u_vedic (
        .a(a), .b(b), .product(p_vedic)
    );

    mul_unit_32b #(.MULT_TYPE(0)) u_mul_array (
        .a(a), .b(b), .funct3(f3), .result(r_array)
    );

    mul_unit_32b #(.MULT_TYPE(1)) u_mul_wallace (
        .a(a), .b(b), .funct3(f3), .result(r_wallace)
    );

    mul_unit_32b #(.MULT_TYPE(2)) u_mul_vedic (
        .a(a), .b(b), .funct3(f3), .result(r_vedic)
    );

    // Compare all three implementations with Verilog multiplication.
    task check_unsigned;
        input [31:0] aa;
        input [31:0] bb;
        begin
            a = aa;
            b = bb;
            f3 = 3'b000;
            #1;

            expected_u = {32'b0, aa} * {32'b0, bb};

            if (p_array !== expected_u) begin
                $display("ARRAY FAIL:   a=%h b=%h exp=%h got=%h",
                         aa, bb, expected_u, p_array);
                errors = errors + 1;
            end

            if (p_wallace !== expected_u) begin
                $display("WALLACE FAIL: a=%h b=%h exp=%h got=%h",
                         aa, bb, expected_u, p_wallace);
                errors = errors + 1;
            end

            if (p_vedic !== expected_u) begin
                $display("VEDIC FAIL:   a=%h b=%h exp=%h got=%h",
                         aa, bb, expected_u, p_vedic);
                errors = errors + 1;
            end
        end
    endtask

    // Check MUL, MULH, MULHSU and MULHU result selection.
    task check_rv32m_mul;
        input [31:0] aa;
        input [31:0] bb;
        input [2:0]  ff;
        begin
            a  = aa;
            b  = bb;
            f3 = ff;
            #1;

            case (ff)
                3'b000: begin // MUL
                    expected_u = {32'b0, aa} * {32'b0, bb};
                    expected_r = expected_u[31:0];
                end

                3'b001: begin // MULH: signed x signed
                    sa64 = {{32{aa[31]}}, aa};
                    sb64 = {{32{bb[31]}}, bb};
                    expected_s = sa64 * sb64;
                    expected_r = expected_s[63:32];
                end

                3'b010: begin // MULHSU: signed x unsigned
                    sa64 = {{32{aa[31]}}, aa};
                    sb64 = {32'b0, bb};
                    expected_s = sa64 * sb64;
                    expected_r = expected_s[63:32];
                end

                default: begin // MULHU: unsigned x unsigned
                    expected_u = {32'b0, aa} * {32'b0, bb};
                    expected_r = expected_u[63:32];
                end
            endcase

            if ((r_array   !== expected_r) ||
                (r_wallace !== expected_r) ||
                (r_vedic   !== expected_r)) begin
                $display("RV32M MUL FAIL: a=%h b=%h funct3=%b exp=%h got A/W/V=%h/%h/%h",
                         aa, bb, ff, expected_r,
                         r_array, r_wallace, r_vedic);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        errors = 0;
        a      = 0;
        b      = 0;
        f3     = 0;

        check_unsigned(32'h00000000, 32'h00000000);
        check_unsigned(32'h00000001, 32'h00000001);
        check_unsigned(32'h00000001, 32'hFFFFFFFF);
        check_unsigned(32'hFFFFFFFF, 32'hFFFFFFFF);
        check_unsigned(32'h80000000, 32'h00000002);
        check_unsigned(32'h80000000, 32'h80000000);
        check_unsigned(32'h7FFFFFFF, 32'h7FFFFFFF);
        check_unsigned(32'hAAAAAAAA, 32'h55555555);
        check_unsigned(32'h12345678, 32'h9ABCDEF0);
        check_unsigned(32'h0000FFFF, 32'hFFFF0000);

        for (i = 0; i < 200; i = i + 1)
            check_unsigned($random, $random);

        check_rv32m_mul(32'd10,       32'd3,        3'b000); // MUL
        check_rv32m_mul(32'hFFFFFFFF, 32'd3,        3'b001); // MULH (-1*3)
        check_rv32m_mul(32'h80000000, 32'hFFFFFFFF, 3'b001); // MULH min* -1
        check_rv32m_mul(32'hFFFFFFFF, 32'd3,        3'b010); // MULHSU
        check_rv32m_mul(32'h80000000, 32'hFFFFFFFF, 3'b010); // MULHSU
        check_rv32m_mul(32'hFFFFFFFF, 32'd3,        3'b011); // MULHU
        check_rv32m_mul(32'hFFFFFFFF, 32'hFFFFFFFF, 3'b011); // MULHU

        for (i = 0; i < 100; i = i + 1) begin
            check_rv32m_mul($random, $random, 3'b000);
            check_rv32m_mul($random, $random, 3'b001);
            check_rv32m_mul($random, $random, 3'b010);
            check_rv32m_mul($random, $random, 3'b011);
        end

        if (errors == 0)
            $display("MULTIPLIER_TB PASS");
        else
            $display("MULTIPLIER_TB FAIL errors=%0d", errors);

        $finish;
    end
endmodule
