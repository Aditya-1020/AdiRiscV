import riscv_pkg::*;

module tb_alu;
    timeunit 1ns;
    timeprecision 1ps;
    
    logic [XLEN-1:0] a, b;
    alu_op_e op;
    logic [XLEN-1:0] result;
    logic zero;

    int pass_count = 0;
    int fail_count = 0;
    int test_num = 0;


    alu dut (
        .a(a),
        .b(b),
        .op(op),
        .result(result),
        .zero(zero)
    );


    task automatic check_result(
        input [XLEN-1:0] expected_result,
        input expected_zero,
        input string test_name
    );

        test_num++;

        if (result != expected_result) begin
            $error("FAIL: Test %0d: %s", test_num, test_name);
            $error("Expected result = 0x%08h, got = 0x%08h", expected_result, result);
            fail_count++;
        end else if (zero !== expected_zero) begin
            $error("FAIL: Test %0d: %s", test_num, test_name);
            $error("Expected result = 0x%08h, got = 0x%08h", expected_result, expected_zero);
            fail_count++;
        end else begin
            $display("PASS: test %0d: %s (result = 0x%08h, zero = %b)", test_num, test_name, result, zero);
            pass_count++;
        end
    endtask


    task automatic run_test(
        input [XLEN-1:0] operand_a,
        input [XLEN-1:0] operand_b,
        input alu_op_e   operation,
        input [XLEN-1:0] expected,
        input            expected_z,
        input string     name
    );
        a = operand_a;
        b = operand_b;
        op = operation;
        #1; // combinational delay
        check_result(expected, expected_z, name);
    endtask

    
    // run_test(a, b, op, expected, expected_zero, name)
    
    task test_add();
        $display("\n Testing ADD");
        run_test(32'd5, 32'd3, ALU_ADD, 32'd8, 1'b0, "ADD: 5 + 3");
        run_test(32'd0, 32'd0, ALU_ADD, 32'd0, 1'b1, "ADD: 0 + 0 (zero flag)");
        run_test(-32'd5, 32'd3, ALU_ADD, -32'd2, 1'b0, "ADD: -5 + 3");
        run_test(32'hFFFFFFFF, 32'd1, ALU_ADD, 32'd0, 1'b1, "ADD: overflow wrap");
        run_test(32'h7FFFFFFF, 32'd1, ALU_ADD, 32'h80000000, 1'b0, "ADD: max positive + 1");
    endtask

    // Test SUB operation
    task test_sub();
        $display("\n Testing SUB ");
        run_test(32'd10, 32'd3, ALU_SUB, 32'd7, 1'b0, "SUB: 10 - 3");
        run_test(32'd5, 32'd5, ALU_SUB, 32'd0, 1'b1, "SUB: 5 - 5 (zero)");
        run_test(32'd0, 32'd5, ALU_SUB, -32'd5, 1'b0, "SUB: 0 - 5");
        run_test(32'd3, 32'd10, ALU_SUB, -32'd7, 1'b0, "SUB: negative result");
        run_test(32'h80000000, 32'd1, ALU_SUB, 32'h7FFFFFFF, 1'b0, "SUB: underflow");
    endtask

    // Test SLL
    task test_sll();
        $display("\n Testing SLL ");
        run_test(32'h00000001, 32'd0,  ALU_SLL, 32'h00000001, 1'b0, "SLL: shift by 0");
        run_test(32'h00000001, 32'd1,  ALU_SLL, 32'h00000002, 1'b0, "SLL: 1 << 1");
        run_test(32'h00000001, 32'd31, ALU_SLL, 32'h80000000, 1'b0, "SLL: 1 << 31");
        run_test(32'hAAAAAAAA, 32'd4,  ALU_SLL, 32'hAAAAAAA0, 1'b0, "SLL: pattern shift");
        run_test(32'h00000001, 32'd32, ALU_SLL, 32'h00000001, 1'b0, "SLL: shift > 31 (wraps)");
        run_test(32'h00000001, 32'd37, ALU_SLL, 32'h00000020, 1'b0, "SLL: shift = 37 (5 mod 32)");
    endtask

    // Test SLT
    task test_slt();
        $display("\n Testing SLT ");
        run_test(32'd5, 32'd10, ALU_SLT, 32'd1, 1'b0, "SLT: 5 < 10");
        run_test(32'd10, 32'd5, ALU_SLT, 32'd0, 1'b1, "SLT: 10 >= 5");
        run_test(-32'd5, 32'd5, ALU_SLT, 32'd1, 1'b0, "SLT: -5 < 5 (signed)");
        run_test(32'd5, -32'd5, ALU_SLT, 32'd0, 1'b1, "SLT: 5 >= -5 (signed)");
        run_test(-32'd10, -32'd5, ALU_SLT, 32'd1, 1'b0, "SLT: -10 < -5");
        run_test(32'h80000000, 32'h7FFFFFFF, ALU_SLT, 32'd1, 1'b0, "SLT: min < max");
    endtask

    // Test SLTU
    task test_sltu();
        $display("\n Testing SLTU ");
        run_test(32'd5, 32'd10, ALU_SLTU, 32'd1, 1'b0, "SLTU: 5 < 10 unsigned");
        run_test(32'd10, 32'd5, ALU_SLTU, 32'd0, 1'b1, "SLTU: 10 >= 5 unsigned");
        run_test(32'hFFFFFFFF, 32'd1, ALU_SLTU, 32'd0, 1'b1, "SLTU: 0xFFFF >= 1 (unsigned)");
        run_test(32'd1, 32'hFFFFFFFF, ALU_SLTU, 32'd1, 1'b0, "SLTU: 1 < 0xFFFF (unsigned)");
        run_test(32'd0, 32'd0, ALU_SLTU, 32'd0, 1'b1, "SLTU: 0 >= 0");
    endtask

    // Test XOR
    task test_xor();
        $display("\n Testing XOR ");
        run_test(32'hAAAAAAAA, 32'h55555555, ALU_XOR, 32'hFFFFFFFF, 1'b0, "XOR: alternating bits");
        run_test(32'hFFFFFFFF, 32'hFFFFFFFF, ALU_XOR, 32'h00000000, 1'b1, "XOR: same bits (zero)");
        run_test(32'h12345678, 32'h0, ALU_XOR, 32'h12345678, 1'b0, "XOR: with zero");
        run_test(32'h12345678, 32'h0000FFFF, ALU_XOR, 32'h1234A987, 1'b0, "XOR: mask");
    endtask

    // Test SRL
    task test_srl();
        $display("\n Testing SRL ");
        run_test(32'h80000000, 32'd1, ALU_SRL, 32'h40000000, 1'b0, "SRL: logical shift");
        run_test(32'hFFFFFFFF, 32'd4, ALU_SRL, 32'h0FFFFFFF, 1'b0, "SRL: fills with zeros");
        run_test(32'hF0000000, 32'd28, ALU_SRL, 32'h0000000F, 1'b0, "SRL: large shift");
        run_test(32'd8, 32'd3, ALU_SRL, 32'd1, 1'b0, "SRL: 8 >> 3");
        run_test(32'd1, 32'd1, ALU_SRL, 32'd0, 1'b1, "SRL: shift to zero");
    endtask

    // Test SRA
    task test_sra();
        $display("\n Testing SRA ");
        run_test(32'h80000000, 32'd1, ALU_SRA, 32'hC0000000, 1'b0, "SRA: sign extends (neg)");
        run_test(32'hFFFFFFF8, 32'd2, ALU_SRA, 32'hFFFFFFFE, 1'b0, "SRA: -8 >> 2");
        run_test(32'd24, 32'd2, ALU_SRA, 32'd6, 1'b0, "SRA: positive >> 2");
        run_test(32'h7FFFFFFF, 32'd1, ALU_SRA, 32'h3FFFFFFF, 1'b0, "SRA: positive (no sign extend)");
        run_test(32'hFFFFFFFF, 32'd31, ALU_SRA, 32'hFFFFFFFF, 1'b0, "SRA: -1 >> 31");
    endtask

    // Test OR
    task test_or();
        $display("\n Testing OR ");
        run_test(32'h00000000, 32'h00000000, ALU_OR, 32'h00000000, 1'b1, "OR: 0 | 0");
        run_test(32'hAAAAAAAA, 32'h55555555, ALU_OR, 32'hFFFFFFFF, 1'b0, "OR: alternating bits");
        run_test(32'hF0F0F0F0, 32'h0F0F0F0F, ALU_OR, 32'hFFFFFFFF, 1'b0, "OR: complement patterns");
        run_test(32'h12345678, 32'h0, ALU_OR, 32'h12345678, 1'b0, "OR: with zero");
    endtask

    // Test AND
    task test_and();
        $display("\n Testing AND ");
        run_test(32'hFFFFFFFF, 32'hFFFFFFFF, ALU_AND, 32'hFFFFFFFF, 1'b0, "AND: all ones");
        run_test(32'hAAAAAAAA, 32'h55555555, ALU_AND, 32'h00000000, 1'b1, "AND: alternating (zero)");
        run_test(32'hFFFFFFFF, 32'h0F0F0F0F, ALU_AND, 32'h0F0F0F0F, 1'b0, "AND: mask");
        run_test(32'h12345678, 32'h0, ALU_AND, 32'h00000000, 1'b1, "AND: with zero");
    endtask

    // pass
    task test_pass();
        $display("\n Testing PASS ");
        run_test(32'h12345678, 32'h87654321, ALU_PASS_A, 32'h12345678, 1'b0, "PASS_A");
        run_test(32'h12345678, 32'h87654321, ALU_PASS_B, 32'h87654321, 1'b0, "PASS_B");
        run_test(32'h00000000, 32'hDEADBEEF, ALU_PASS_A, 32'h00000000, 1'b1, "PASS_A zero");
    endtask

    initial begin
        $dumpfile("alu.vcd");
        $dumpvars(0, tb_alu);

        a = '0;
        b = '0;
        op = ALU_ADD;
        #1;

        test_add();
        test_sub();
        test_sll();
        test_slt();
        test_sltu();
        test_xor();
        test_srl();
        test_sra();
        test_or();
        test_and();
        test_pass();

        $display("Test Summary");
        $display("Total Tests: %0d", pass_count + fail_count);
        $display("Passed:      %0d", pass_count);
        $display("Failed:      %0d", fail_count);

        if (fail_count == 0) begin
            $display("all passe");
        end else begin
            $display("%0d failed", fail_count);
        end
        #10;
        $finish;
    end
    
    initial begin
        #10000;
        $error("TIMEOUT: Tb did not compile in time");
        $finish;
    end

endmodule