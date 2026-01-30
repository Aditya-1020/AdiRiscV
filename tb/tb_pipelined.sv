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

    // Test configuration
    typedef struct {
        string name;
        string hex_file;
        int max_cycles;
        bit enable_trace;
    } test_config_t;


    task automatic load_program(string filename);
        string full_path;
        full_path = {"programs/", filename};
        
        // Clear memory first
        for (int i = 0; i < IMEM_SIZE; i++) begin
            dut.mem_ctrl.imem[i] = NOP_INSTR;
        end
        for (int i = 0; i < DMEM_SIZE; i++) begin
            dut.mem_ctrl.dmem[i] = 8'h0;
        end
        
        $readmemh(full_path, dut.mem_ctrl.imem);
        $display("  [INFO] Loaded program: %s", filename);
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
            $display("     PASS: x%0d = 0x%08h - %s", reg_num, actual, name);
            pass_count++;
        end else begin
            $display("     FAIL: x%0d = 0x%08h (expected 0x%08h) - %s", reg_num, actual, expected, name);
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
            $display("     PASS: mem[0x%08h] = 0x%08h - %s", addr, actual, name);
            pass_count++;
        end else begin
            $display("     FAIL: mem[0x%08h] = 0x%08h (expected 0x%08h) - %s",
                    addr, actual, expected, name);
            fail_count++;
        end
    endtask

    task automatic display_regfile();
        $display("\n  Register File State:");
        for (int i = 0; i < 32; i++) begin
            if (dut.id_stage_inst.regfile_inst.registers[i] != 0) begin
                $display("    x%0d = 0x%08h (%0d)", i,  // FIXED: consistent formatting
                        dut.id_stage_inst.regfile_inst.registers[i],
                        $signed(dut.id_stage_inst.regfile_inst.registers[i]));
            end
        end
    endtask

    task automatic display_performance();
        $display("\n  Performance Metrics:");
        $display("    Cycles:           %0d", dut.perf_cycles);
        $display("    Instructions:     %0d", dut.perf_instructions);
        $display("    Branches:         %0d", dut.perf_branches);
        $display("    Branch Misses:    %0d", dut.perf_branch_misses);
        $display("    Stalls:           %0d", dut.perf_stalls);
        $display("    IPC:              %0.3f", dut.perf_counters_inst.ipc);
        
        if (dut.perf_branches > 0)
            $display("    Branch Miss Rate: %0.2f%%", dut.perf_counters_inst.branch_miss_rate);
    endtask

    task automatic run_test_with_trace(int max_cycles);
        int cycle = 0;
        
        $display("\n  Trace (first 20 cycles):");
        $display("  %s", {60{"-"}});
        
        while (cycle < max_cycles) begin
            @(posedge clk);
            cycle++;
            
            if (cycle <= 20) begin
                $display("  [%3d] PC=0x%08h | IF/ID=%b ID/EX=%b EX/MEM=%b MEM/WB=%b | Stalls: pc=%b ex=%b",
                        cycle,
                        dut.if_stage_inst.pc,
                        dut.if_id_reg_out.valid_if_id,
                        dut.id_ex_reg_out.valid_id_ex,
                        dut.ex_mem_out.valid_ex_mem,
                        dut.mem_wb_out.valid_mem_wb,
                        dut.pc_stall,
                        dut.ex_stall);
                
                if (dut.wb_reg_write) begin
                    $display("        WB: x%0d = 0x%08h", dut.wb_rd_addr, dut.wb_write_data);
                end
                
                if (dut.branch_taken) begin
                    $display("        BRANCH TAKEN -> 0x%08h", dut.branch_target);
                end
            end
        end
    endtask

    task automatic run_test_silent(int max_cycles);
        repeat(max_cycles) @(posedge clk);
    endtask

    // Test 0: Simple Sanity Check
    task automatic test_simple();
        int local_pass = 0, local_fail = 0;

        $display("\n╔════════════════════════════════════════════════════╗");
        $display("║  TEST 0: Simple Sanity Check                       ║");
        $display("╚════════════════════════════════════════════════════╝");

        load_program("test_simple.hex");
        reset_core();
        run_test_with_trace(20);

        $display("\n  Checking Results:");
        check_reg(5, 32'd5, "x5 = 5", local_pass, local_fail);
        check_reg(6, 32'd10, "x6 = 10", local_pass, local_fail);
        check_reg(7, 32'd15, "x7 = 5+10", local_pass, local_fail);
        check_reg(8, 32'hFFFFFFFB, "x8 = 5-10 = -5", local_pass, local_fail);

        display_performance();

        passed_tests += local_pass;
        failed_tests += local_fail;
        total_tests++;
    endtask

    // Test 1: Basic ALU Operations
    task automatic test_basic_alu();
        int local_pass = 0, local_fail = 0;
        
        $display("\n╔════════════════════════════════════════════════════╗");
        $display("║  TEST 1: Basic ALU Operations                      ║");
        $display("╚════════════════════════════════════════════════════╝");
        
        load_program("TEST.hex");
        reset_core();
        run_test_silent(40);
        
        $display("\n  Checking Results:");
        check_reg(5,  32'd10, "x5 = 10 (addi)", local_pass, local_fail);
        check_reg(6,  32'd20, "x6 = 20 (addi)", local_pass, local_fail);
        check_reg(7,  32'd30, "x7 = 30 (add)", local_pass, local_fail);
        // FIXED: Correct expected value for subtraction
        check_reg(8,  32'hFFFFFFF6, "x8 = 10-20 = -10 (sub)", local_pass, local_fail);
        
        display_performance();
        
        passed_tests += local_pass;
        failed_tests += local_fail;
        total_tests++;
    endtask

    // Test 2: Load/Store Operations
        task automatic test_load_store();
        int local_pass = 0, local_fail = 0;
        
        $display("\n╔════════════════════════════════════════════════════╗");
        $display("║  TEST 2: Load/Store Operations                     ║");
        $display("╚════════════════════════════════════════════════════╝");
        
        load_program("test_mem.hex");
        reset_core();
        run_test_silent(50);

        // DEBUG: dump the relevant registers and memory
        $display("\n  [DEBUG] After run_test_silent(50):");
        $display("    x24 = 0x%08h", dut.id_stage_inst.regfile_inst.registers[24]);
        $display("    x25 = 0x%08h", dut.id_stage_inst.regfile_inst.registers[25]);
        $display("    x27 = 0x%08h", dut.id_stage_inst.regfile_inst.registers[27]);
        $display("    mem[0x00000000] = 0x%08h", 
            {dut.mem_ctrl.dmem[3], dut.mem_ctrl.dmem[2], dut.mem_ctrl.dmem[1], dut.mem_ctrl.dmem[0]});
        $display("    mem[0x00000002] = 0x%08h", 
            {dut.mem_ctrl.dmem[5], dut.mem_ctrl.dmem[4], dut.mem_ctrl.dmem[3], dut.mem_ctrl.dmem[2]});

        // Optional: dump the whole regfile for context
        display_regfile();

        $display("\n  Checking Results:");
        
        check_mem(32'h00000000, 32'h000000FF, "SB stored byte at offset 0", local_pass, local_fail);
        check_reg(24, 32'h000000FF, "LBU zero-extended", local_pass, local_fail);
        check_reg(25, 32'hFFFFFFFF, "LB sign-extended", local_pass, local_fail);
        check_reg(27, 32'h00004000, "LHU loaded halfword", local_pass, local_fail);
        
        display_performance();
        
        passed_tests += local_pass;
        failed_tests += local_fail;
        total_tests++;
    endtask


    // Test 3: Branch Operations
    task automatic test_branches();
        int local_pass = 0, local_fail = 0;
        
        $display("\n╔════════════════════════════════════════════════════╗");
        $display("║  TEST 3: Branch Operations                         ║");
        $display("╚════════════════════════════════════════════════════╝");
        
        load_program("test_branch.hex");
        reset_core();
        run_test_with_trace(60);
        
        $display("\n  Checking Results:");
        check_reg(1, 32'd10, "BEQ setup value", local_pass, local_fail);
        check_reg(2, 32'd20, "BNE target executed", local_pass, local_fail);
        check_reg(3, 32'd10, "Final value after branches", local_pass, local_fail);
        
        display_performance();
        
        if (dut.perf_branches > 0) begin
            if (dut.perf_counters_inst.branch_miss_rate < 50.0) begin
                $display("     Branch predictor working (<%0.1f%% miss)", 
                        dut.perf_counters_inst.branch_miss_rate);
                local_pass++;
            end else begin
                $display("     High branch miss rate (%0.1f%%)", 
                        dut.perf_counters_inst.branch_miss_rate);
            end
        end
        
        passed_tests += local_pass;
        failed_tests += local_fail;
        total_tests++;
    endtask

    // Test 4: Hazard Detection
    task automatic test_hazards();
        int local_pass = 0, local_fail = 0;
        
        $display("\n╔════════════════════════════════════════════════════╗");
        $display("║  TEST 4: Hazard Detection & Forwarding            ║");
        $display("╚════════════════════════════════════════════════════╝");
        
        load_program("test_hazards.hex");
        reset_core();
        run_test_with_trace(50);
        
        $display("\n  Checking Results:");
        check_reg(5, 32'd42, "Initial value", local_pass, local_fail);
        check_reg(6, 32'd47, "RAW hazard resolved (42+5)", local_pass, local_fail);
        check_reg(7, 32'd94, "Double RAW (47+47)", local_pass, local_fail);
        
        display_performance();
        
        passed_tests += local_pass;
        failed_tests += local_fail;
        total_tests++;
    endtask

    // Test 5: M-Extension (Multiply/Divide)
    task automatic test_m_extension();
        int local_pass = 0, local_fail = 0;
        
        $display("\n╔════════════════════════════════════════════════════╗");
        $display("║  TEST 5: M-Extension (Multiply/Divide)            ║");
        $display("╚════════════════════════════════════════════════════╝");
        
        load_program("test_mext.hex");
        reset_core();
        run_test_silent(150);
        
        $display("\n  Checking Results:");
        check_reg(5, 32'd50, "MUL: 10 * 5 = 50", local_pass, local_fail);
        check_reg(7, 32'd0, "MULH: upper 32 bits", local_pass, local_fail);
        check_reg(10, 32'd6, "DIV: 20 / 3 = 6", local_pass, local_fail);
        check_reg(11, 32'd2, "REM: 20 % 3 = 2", local_pass, local_fail);
        
        if (dut.perf_stalls >= 32) begin
            $display("     Division stalls detected (%0d cycles)", dut.perf_stalls);
            local_pass++;
        end else begin
            $display("Expected ~64 division stalls, got %0d", dut.perf_stalls);
        end
        
        display_performance();
        
        passed_tests += local_pass;
        failed_tests += local_fail;
        total_tests++;
    endtask

    // Test 6: Jump Instructions (JAL/JALR)
    task automatic test_jumps();
        int local_pass = 0, local_fail = 0;
        
        $display("\n╔════════════════════════════════════════════════════╗");
        $display("║  TEST 6: Jump Instructions (JAL/JALR)             ║");
        $display("╚════════════════════════════════════════════════════╝");
        
        load_program("test_jumps.hex");
        reset_core();
        run_test_with_trace(40);
        
        $display("\n  Checking Results:");
        check_reg(1, 32'h00000004, "JAL return address", local_pass, local_fail);
        check_reg(10, 32'd999, "JAL target executed", local_pass, local_fail);
        
        display_performance();
        
        passed_tests += local_pass;
        failed_tests += local_fail;
        total_tests++;
    endtask

    // Test 7: Edge Cases
    task automatic test_edge_cases();
        int local_pass = 0, local_fail = 0;
        
        $display("\n╔════════════════════════════════════════════════════╗");
        $display("║  TEST 7: Edge Cases                                ║");
        $display("╚════════════════════════════════════════════════════╝");
        
        load_program("test_edge.hex");
        reset_core();
        run_test_silent(50);
        
        $display("\n  Checking Results:");
        check_reg(0, 32'd0, "x0 always zero", local_pass, local_fail);
        check_reg(5, 32'h80000000, "Overflow wraps", local_pass, local_fail);
        check_reg(6, 32'd0, "SLTIU edge case", local_pass, local_fail);
        check_reg(7, 32'hAAAAA000, "SLL by 0 unchanged", local_pass, local_fail);
        
        display_performance();
        
        passed_tests += local_pass;
        failed_tests += local_fail;
        total_tests++;
    endtask

    initial begin
        $dumpfile("pipelined.vcd");
        $dumpvars(0, tb_pipelined);

        $display("\n");
        $display("╔════════════════════════════════════════════════════╗");
        $display("║  RISC-V Pipelined Core - Comprehensive Test Suite ║");
        $display("╚════════════════════════════════════════════════════╝");
        $display("");

        reset = 1;
        
        // Run all tests
        test_simple();
        test_basic_alu();
        test_load_store();
        test_branches();
        test_hazards();
        test_m_extension();
        test_jumps();
        test_edge_cases();

        // Final Summary
        $display("\n");
        $display("╔════════════════════════════════════════════════════╗");
        $display("║  TEST SUMMARY                                      ║");
        $display("╚════════════════════════════════════════════════════╝");
        $display("  Total Test Suites:  %0d", total_tests);
        $display("  Assertions Passed:  %0d", passed_tests);
        $display("  Assertions Failed:  %0d", failed_tests);
        $display("");
        
        if (failed_tests == 0) begin
            $display("ALL TESTS PASSED");
        end else begin
            $display("SOME TESTS FAILED");
        end
        
        $display("");
        $finish;
    end

    initial begin
        #200000;
        $display("\n[ERROR] Timeout - Test suite did not complete");
        $finish;
    end

endmodule