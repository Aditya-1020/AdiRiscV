import riscv_pkg::*;

module tb_pc;

    timeunit 1ns;
    timeprecision 1ps;

    logic clk, reset;
    logic pc_en;
    logic [XLEN-1:0] pc_next, pc;

    int pass_count = 0;
    int fail_count = 0;

    pc dut (
        .clk(clk),
        .reset(reset),
        .pc_en(pc_en),
        .pc_next(pc_next),
        .pc(pc)
    );

    initial clk = 0;
    always #5 clk = ~clk; // 100 mhz

    task automatic check_pc(
        input string test_name,
        input logic [XLEN-1:0] expected_pc
    );

        @(posedge clk);
        #1;

        if (pc !== expected_pc) begin
            $display("FAIL: %s, expected=0x%08h, got=0x%08h", test_name, expected_pc, pc);
            fail_count++;
        end else begin
            $display("PASS: %s pc=0x%08h", test_name, pc);
            pass_count++;
        end
    endtask

    task automatic test_reset;
        $display("\ntest reset");
        reset = 1;
        pc_en = 0;
        pc_next = 32'h12345678;

        @(posedge clk);
        #1;

        if (pc !== RESET_PC) begin
            $display("FAIL: Reset pc Expected= 0x%08h, Got= 0x%08h", RESET_PC, pc);
            fail_count++;
        end else begin
            $display("PASS: Reset pc = 0x%08h", pc);
            pass_count++;
        end

        // hold reset for another cycle
        @(posedge clk);
        #1;
        if (pc !== RESET_PC) begin
            $display("FAIL: reset hold");
            fail_count++;
        end else begin
            $display("PASS: reset hold");
            pass_count++;
        end
        reset = 0;
    endtask

    task automatic test_pc_enable;
        $display("\ntest pc enable");

        reset = 1;
        @(posedge clk);
        reset = 0;

        pc_en = 1;
        pc_next = 32'h00001000;
        check_pc("PC enable", 32'h00001000);

        // pc disable
        pc_en = 0;
        pc_next = 32'h00002000;
        check_pc("Pc disabled", 32'h00001000);

        pc_next = 32'h00003000;
        check_pc("pc disabled testing hold at 0x1000", 32'h00001000);

        // reenabled
        pc_en = 1;
        pc_next = 32'h00004000;
        check_pc("pc re-enabled", 32'h00004000);
    endtask

    // pc update
    task automatic test_sequential_update;
        $display("\nTest sequential update");

        reset = 1;
        @(posedge clk);
        reset = 0;

        for (int i = 0; i < 10; i++) begin
            pc_next = RESET_PC + (i * 4);
            check_pc($sformatf("Squential pc[%0d]", i), RESET_PC + (i * 4));
        end
    endtask

    task automatic test_branch;
        $display("\nTest branch");

        reset = 1;
        @(posedge clk);
        reset = 0;
        pc_en = 1;

        /// incerment
        pc_next = 32'h00001000;
        check_pc("branch test: pc to 0x1000", 32'h00001000);

        // branch forward jump
        pc_next = 32'h00002000;
        check_pc("branch forward to 0x2000", 32'h00002000);

        // back backward
        pc_next = 32'h00000100;
        check_pc("brach backward to 0x0100", 32'h00000100);

        // large jump
        pc_next = 32'hFFFF0000;
        check_pc("large jump to 0xFFFF0000", 32'hFFFF0000);
    endtask

    // reset during operation
    task automatic reset_under_operation;
        $display("\ntest reest under operation");
        reset = 0;
        pc_en = 1;

        pc_next= 32'h12345678;
        @(posedge clk);
        reset  = 1;
        pc_next = 32'h87654321;
        check_pc("reset overide write",RESET_PC);
        reset = 0;
    endtask

    task automatic test_edge_cases;
        $display("\ntest edge case");
        reset = 1;
        @(posedge clk);
        reset = 0;
        pc_en = 1;

        // zero
        pc_next = 32'h00000000;
        check_pc("Pc 0x'0", 32'h00000000);

        // max
        pc_next = 32'hFFFFFFFF;
        check_pc("max at 0xFFFFFFFF", 32'hFFFFFFFF);

        // aligned addresses
        pc_next = 32'h00001001; //odd
        check_pc("Pc 0x00001001 (missaligned)", 32'h00001001);

        pc_next = 32'h00001002; //halfword
        check_pc("Pc 0x00001002 (halfword)", 32'h00001002);
    endtask

    initial begin
        $dumpfile("tb_pc.vcd");
        $dumpvars(0, tb_pc);
        
        $display("\nPC tests");

        reset = 0;
        pc_en = 0;
        pc_next = '0;

        #1;

        test_reset();
        test_pc_enable();
        test_sequential_update();
        test_branch();
        reset_under_operation();
        test_edge_cases();

        $display("\nsummary");
        $display("passed: %0d", pass_count);
        $display("failed: %0d", fail_count);
        $display("total: %0d", pass_count + fail_count);
        if (fail_count == 0)
            $display("all test passed");
        else
            $display("some test failed");

        $finish;
    end


    initial begin
        #10000;
        $error("\nTIMEOUT: Tb did not compile in time");
        $finish;
    end

endmodule