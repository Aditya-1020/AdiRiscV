import riscv_pkg::*;

module tb_pipelined;
    timeunit 1ns;
    timeprecision 1ps;

    logic clk;
    logic reset;
    
    int total_tests = 0;
    int passed_tests = 0;
    int failed_tests = 0;

    initial clk = 0;
    always #5 clk = ~clk; // 100MHz

    riscv_pipelined_core dut (
        .clk(clk),
        .reset(reset)
    );

    task automatic load_program(string filename);
        string full_path;
        full_path = {"programs/", filename};
        
        for (int i = 0; i < IMEM_SIZE; i++) begin
            dut.mem_ctrl.imem[i] = NOP_INSTR;
        end
        for (int i = 0; i < DMEM_SIZE; i++) begin
            dut.mem_ctrl.dmem[i] = 8'h0;
        end
        
        $readmemh(full_path, dut.mem_ctrl.imem);
    endtask

    task automatic reset_core();
        reset = 1;
        repeat(5) @(posedge clk);
        reset = 0;
        @(posedge clk);
    endtask

    task automatic check_reg(
        int reg_num, 
        logic [31:0] expected, 
        string name,
        ref int pass_count,
        ref int fail_count
    );
        logic [31:0] actual;
        actual = dut.id_stage_inst.regfile_inst.registers[reg_num];
        
        if (actual == expected) begin
            pass_count++;
        end else begin
            $display("FAIL: x%0d = 0x%08h (expected 0x%08h) - %s", reg_num, actual, expected, name);
            fail_count++;
        end
    endtask

    task automatic check_mem(
        logic [31:0] addr,
        logic [31:0] expected,
        string name,
        ref int pass_count,
        ref int fail_count
    );
        logic [31:0] actual;
        logic [31:0] byte_addr;
        
        byte_addr = addr[BYTE_ADDR_WIDTH-1:0];
        actual = {dut.mem_ctrl.dmem[byte_addr + 3],
                  dut.mem_ctrl.dmem[byte_addr + 2],
                  dut.mem_ctrl.dmem[byte_addr + 1],
                  dut.mem_ctrl.dmem[byte_addr + 0]};
        
        if (actual == expected) begin
            pass_count++;
        end else begin
            $display("FAIL: mem[0x%08h] = 0x%08h (expected 0x%08h) - %s", addr, actual, expected, name);
            fail_count++;
        end
    endtask

    task automatic run_test(int max_cycles);
        repeat(max_cycles) @(posedge clk);
    endtask

    task automatic test_simple();
        int local_pass = 0, local_fail = 0;
        load_program("test_simple.hex");
        reset_core();
        run_test(20);
        check_reg(5, 32'd5, "x5 = 5", local_pass, local_fail);
        check_reg(6, 32'd10, "x6 = 10", local_pass, local_fail);
        check_reg(7, 32'd15, "x7 = 5+10", local_pass, local_fail);
        check_reg(8, 32'hFFFFFFFB, "x8 = 5-10", local_pass, local_fail);
        passed_tests += local_pass;
        failed_tests += local_fail;
        total_tests++;
    endtask

    task automatic test_basic_alu();
        int local_pass = 0, local_fail = 0;
        load_program("TEST.hex");
        reset_core();
        run_test(40);
        check_reg(5, 32'd10, "ADDI", local_pass, local_fail);
        check_reg(6, 32'd20, "ADDI", local_pass, local_fail);
        check_reg(7, 32'd30, "ADD", local_pass, local_fail);
        check_reg(8, 32'hFFFFFFF6, "SUB", local_pass, local_fail);
        passed_tests += local_pass;
        failed_tests += local_fail;
        total_tests++;
    endtask

    task automatic test_load_store();
        int local_pass = 0, local_fail = 0;
        load_program("test_mem.hex");
        reset_core();
        run_test(50);
        check_mem(32'h00000000, 32'h000000FF, "SB", local_pass, local_fail);
        check_reg(24, 32'hFFFFFFFF, "LB", local_pass, local_fail);
        check_reg(25, 32'h000000FF, "LBU", local_pass, local_fail);
        check_reg(27, 32'h00004000, "LHU", local_pass, local_fail);
        passed_tests += local_pass;
        failed_tests += local_fail;
        total_tests++;
    endtask

    task automatic test_branches();
        int local_pass = 0, local_fail = 0;
        load_program("test_branch.hex");
        reset_core();
        run_test(60);
        check_reg(1, 32'd10, "BEQ", local_pass, local_fail);
        check_reg(2, 32'd20, "BNE", local_pass, local_fail);
        check_reg(3, 32'd10, "Branch", local_pass, local_fail);
        passed_tests += local_pass;
        failed_tests += local_fail;
        total_tests++;
    endtask

    task automatic test_hazards();
        int local_pass = 0, local_fail = 0;
        load_program("test_hazards.hex");
        reset_core();
        run_test(50);
        check_reg(5, 32'd42, "RAW", local_pass, local_fail);
        check_reg(6, 32'd47, "Forwarding", local_pass, local_fail);
        check_reg(7, 32'd94, "Double RAW", local_pass, local_fail);
        passed_tests += local_pass;
        failed_tests += local_fail;
        total_tests++;
    endtask

    task automatic test_m_extension();
        int local_pass = 0, local_fail = 0;
        load_program("test_mext.hex");
        reset_core();
        run_test(150);
        check_reg(5, 32'd50, "MUL", local_pass, local_fail);
        check_reg(7, 32'd0, "MULH", local_pass, local_fail);
        check_reg(10, 32'd6, "DIV", local_pass, local_fail);
        check_reg(11, 32'd2, "REM", local_pass, local_fail);
        passed_tests += local_pass;
        failed_tests += local_fail;
        total_tests++;
    endtask

    task automatic test_jumps();
        int local_pass = 0, local_fail = 0;
        load_program("test_jumps.hex");
        reset_core();
        run_test(40);
        check_reg(1, 32'h00000004, "JAL", local_pass, local_fail);
        check_reg(10, 32'd999, "JAL target", local_pass, local_fail);
        passed_tests += local_pass;
        failed_tests += local_fail;
        total_tests++;
    endtask

    task automatic test_edge_cases();
        int local_pass = 0, local_fail = 0;
        load_program("test_edge.hex");
        reset_core();
        run_test(50);
        check_reg(0, 32'd0, "x0", local_pass, local_fail);
        check_reg(5, 32'h80000000, "Overflow", local_pass, local_fail);
        check_reg(6, 32'd0, "SLTIU", local_pass, local_fail);
        check_reg(7, 32'hAAAAA000, "SLL", local_pass, local_fail);
        passed_tests += local_pass;
        failed_tests += local_fail;
        total_tests++;
    endtask

    initial begin
        $dumpfile("pipelined.vcd");
        $dumpvars(0, tb_pipelined);

        $display("   _____       .___.____________.__            ____   ____");
        $display("  /  _  \\    __| _/|__\\______   \\__| ______ ___\\   \\ /   /");
        $display(" /  /_\\  \\  / __ | |  ||       _/  |/  ___// ___\\   Y   / ");
        $display("/    |    \\/ /_/ | |  ||    |   \\  |\\___ \\\\  \\___\\     /  ");
        $display("\\____|__  /\\____ | |__||____|_  /__/____  >\\___  >\\___/   ");
        $display("        \\/      \\/            \\/        \\/     \\/");


        reset = 1;
        
        test_simple();
        test_basic_alu();
        test_load_store();
        test_branches();
        test_hazards();
        test_m_extension();
        test_jumps();
        test_edge_cases();

        $display("\n=== Performance Metrics ===");
        $display("Cycles:              %0d", dut.perf_cycles);
        $display("Instructions:        %0d", dut.perf_instructions);
        $display("IPC:                 %0.3f", dut.perf_counters_inst.ipc);
        $display("Branches:            %0d", dut.perf_branches);
        $display("Branch Misses:       %0d", dut.perf_branch_misses);
        $display("Branch Miss Rate:    %0.2f%%", dut.perf_counters_inst.branch_miss_rate);
        $display("Pipeline Stalls:     %0d", dut.perf_stalls);
        
        $display("\n=== Test Results ===");
        $display("Test Suites:         %0d", total_tests);
        $display("Assertions Passed:   %0d", passed_tests);
        $display("Assertions Failed:   %0d", failed_tests);
        
        if (failed_tests == 0) begin
            $display("\nRESULT: ALL TESTS PASSED\n");
        end else begin
            $display("\nRESULT: %0d TESTS FAILED\n", failed_tests);
        end
        
        $finish;
    end

    initial begin
        #200000;
        $display("\nERROR: Timeout");
        $finish;
    end

endmodule