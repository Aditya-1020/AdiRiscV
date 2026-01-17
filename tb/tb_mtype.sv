import riscv_pkg::*;

module tb_mtype;

    timeunit 1ns;
    timeprecision 1ps;

    logic clk, reset;
    logic [XLEN-1:0] a, b;
    alu_op_e op;
    logic [XLEN-1:0] result;
    logic zero, ready;

    int pass_count = 0;
    int fail_count = 0;

    initial clk = 0;
    always #5 clk = ~clk;

    alu dut (
        .a(a),
        .b(b),
        .op(op),
        .result(result),
        .zero(zero),
        .ready(ready)
    );


     task automatic test_op(
        input logic [31:0] val_a,
        input logic [31:0] val_b,
        input alu_op_e operation,
        input logic [31:0] expected,
        input string name
    );
        a = val_a;
        b = val_b;
        op = operation;
        
        // Wait for result to be ready
        wait(ready);
        @(posedge clk);
        #1;
        
        if (result == expected) begin
            $display("PASS: %s (0x%08h)", name, result);
            pass_count++;
        end else begin
            $error("FAIL: %s - expected 0x%08h, got 0x%08h", name, expected, result);
            fail_count++;
        end
    endtask

    /*
    // Monitor divider signals
    initial begin
        forever begin
            @(posedge clk);
            if (dut.is_div_op) begin
                $display("[%0t] DIV OP: start=%b, busy=%b, done=%b, ready=%b, div_result=0x%08h", 
                         $time, dut.div_start, dut.div_busy, dut.div_done, ready, dut.div_result);
            end
        end
    end
    */
    initial begin
        $dumpfile("m_extension.vcd");
        $dumpvars(0, tb_mtype);
        
        reset = 1;
        a = 0;
        b = 0;
        op = ALU_ADD;
        
        repeat(3) @(posedge clk);
        reset = 0;
        repeat(1) @(posedge clk);
        
        $display("RV32M Test");
        
        // MULTIPLY Test
        $display("MUL Test");
        test_op(32'd10, 32'd5, ALU_MUL, 32'd50, "MUL: 10 x 5");
        test_op(32'd100, 32'd100, ALU_MUL, 32'd10000, "MUL: 100 x 100");
        test_op(-32'd5, 32'd3, ALU_MUL, -32'd15, "MUL: -5 x 3");
        test_op(-32'd1, -32'd1, ALU_MUL, 32'd1, "MUL: -1 x -1");
        test_op(32'h80000000, 32'd2, ALU_MUL, 32'd0, "MUL: overflow lower bits");
        
        $display("\nMULH Test (signed x signed)");
        test_op(32'h80000000, 32'd2, ALU_MULH, 32'hFFFFFFFF, "MULH: 0x80000000 x 2");
        test_op(-32'd1, -32'd1, ALU_MULH, 32'd0, "MULH: -1 x -1");
        test_op(32'd100000, 32'd100000, ALU_MULH, 32'd2, "MULH: 100000 x 100000");
        
        $display("\nMULHSU Test (signed x unsigned)");
        test_op(-32'd1, 32'd10, ALU_MULHSU, 32'hFFFFFFFF, "MULHSU: -1 x 10");
        test_op(32'd5, 32'hFFFFFFFF, ALU_MULHSU, 32'd4, "MULHSU: 5 x 0xFFFFFFFF");
        
        $display("\nMULHU Test (unsigned x unsigned)");
        test_op(32'hFFFFFFFF, 32'hFFFFFFFF, ALU_MULHU, 32'hFFFFFFFE, "MULHU: 0xFFFFFFFF x 0xFFFFFFFF");
        test_op(32'h80000000, 32'd2, ALU_MULHU, 32'd1, "MULHU: 0x80000000 x 2");
        
        // DIVISION Test
        $display("\nDIV Test (signed)");
        test_op(32'd20, 32'd3, ALU_DIV, 32'd6, "DIV: 20 / 3");
        test_op(-32'd20, 32'd3, ALU_DIV, -32'd6, "DIV: -20 / 3");
        test_op(32'd20, -32'd3, ALU_DIV, -32'd6, "DIV: 20 / -3");
        test_op(-32'd20, -32'd3, ALU_DIV, 32'd6, "DIV: -20 / -3");
        test_op(32'd7, 32'd0, ALU_DIV, 32'hFFFFFFFF, "DIV: 7 / 0 = -1");
        test_op(32'h80000000, -32'd1, ALU_DIV, 32'h80000000, "DIV: overflow");
        
        $display("\nDIVU Test (unsigned)");
        test_op(32'd20, 32'd3, ALU_DIVU, 32'd6, "DIVU: 20 / 3");
        test_op(32'hFFFFFFFF, 32'd2, ALU_DIVU, 32'h7FFFFFFF, "DIVU: 0xFFFFFFFF / 2");
        test_op(32'd100, 32'd10, ALU_DIVU, 32'd10, "DIVU: 100 / 10");
        test_op(32'd7, 32'd0, ALU_DIVU, 32'hFFFFFFFF, "DIVU: 7 / 0 = -1");
        
        $display("\nREM Test (signed remainder)");
        test_op(32'd20, 32'd3, ALU_REM, 32'd2, "REM: 20 % 3");
        test_op(-32'd20, 32'd3, ALU_REM, -32'd2, "REM: -20 % 3");
        test_op(32'd20, -32'd3, ALU_REM, 32'd2, "REM: 20 % -3");
        test_op(-32'd20, -32'd3, ALU_REM, -32'd2, "REM: -20 % -3");
        test_op(32'd7, 32'd0, ALU_REM, 32'd7, "REM: 7 % 0 = 7");
        
        $display("\nREMU Test (unsigned remainder)");
        test_op(32'd20, 32'd3, ALU_REMU, 32'd2, "REMU: 20 % 3");
        test_op(32'hFFFFFFFF, 32'd10, ALU_REMU, 32'd5, "REMU: 0xFFFFFFFF % 10");
        test_op(32'd7, 32'd0, ALU_REMU, 32'd7, "REMU: 7 % 0 = 7");
        
        // Edge Cases
        $display("\nEdge Cases");
        test_op(32'd0, 32'd5, ALU_MUL, 32'd0, "MUL: 0 x 5");
        test_op(32'd0, 32'd5, ALU_DIV, 32'd0, "DIV: 0 / 5");
        test_op(32'd5, 32'd1, ALU_DIV, 32'd5, "DIV: 5 / 1");
        test_op(32'd5, 32'd5, ALU_DIV, 32'd1, "DIV: 5 / 5");
        
        // Summary
        repeat(5) @(posedge clk);
        
        $display("Test Summary");
        $display("Total:  %0d", pass_count + fail_count);
        $display("Passed: %0d", pass_count);
        $display("Failed: %0d", fail_count);
        
        if (fail_count == 0) begin
            $display("\nall tests passed!");
        end else begin
            $display("\nsome tests failed");
        end

        $finish;
    end
    
    initial begin
        #50000;
        $error("TIMEOUT: Testbench did not complete");
        $finish;
    end


endmodule