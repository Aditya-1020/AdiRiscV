import riscv_pkg::*;

module tb_pipelined;

    timeunit 1ns;
    timeprecision 1ps;

    logic clk;
    logic reset;

    initial clk = 0;
    always #5 clk = ~clk; // 100MHz

    riscv_pipelined_core dut (
        .clk(clk),
        .reset(reset)
    );

    task automatic load_program();
        // Load simple test program directly
        $readmemh("programs/TEST.hex", dut.mem_ctrl.imem);
        $display("[INFO] loaded into instruction memory");
    endtask

    task automatic check_reg(int reg_num, logic [31:0] expected, string name);
        logic [31:0] actual;
        actual = dut.id_stage_inst.regfile_inst.registers[reg_num];
        if (actual == expected) begin
            $display("  ✓ PASS: x%-2d = 0x%08h - %s", reg_num, actual, name);
        end else begin
            $display("  ✗ FAIL: x%-2d = 0x%08h (expected 0x%08h) - %s", 
                    reg_num, actual, expected, name);
        end
    endtask

    initial begin
        $dumpfile("pipelined.vcd");
        $dumpvars(0, tb_pipelined);

        $display("\n========================================");
        $display(" Simple Pipeline Test");
        $display("========================================\n");

        reset = 1;
        load_program();

        repeat(5) @(posedge clk);
        reset = 0;
        $display("[INFO] Starting execution...\n");

        // Run for enough cycles
        repeat(100) @(posedge clk);

        $display("\n========================================");
        $display(" TEST RESULTS");
        $display("========================================");
        
        check_reg(5,  32'd10, "x5 = 10");
        check_reg(6,  32'd20, "x6 = 20");
        check_reg(7,  32'd30, "x7 = 10 + 20");
        check_reg(8,  32'd10, "x8 = 20 - 10");
        check_reg(4,  32'd1,  "x4 = 1 (branch taken)");
        check_reg(13, 32'd100, "x13 = 100 (JAL worked)");
        check_reg(29, 32'd170, "x29 = 0xAA");
        check_reg(30, 32'd187, "x30 = 0xBB");
        check_reg(31, 32'd204, "x31 = 0xCC");

        $display("\n========================================");
        $display(" All Registers:");
        $display("========================================");
        for (int i = 1; i < 32; i++) begin
            if (dut.id_stage_inst.regfile_inst.registers[i] != 0) begin
                $display("  x%-2d = 0x%08h (%0d)", i,
                        dut.id_stage_inst.regfile_inst.registers[i],
                        $signed(dut.id_stage_inst.regfile_inst.registers[i]));
            end
        end
        $display("========================================\n");

        $finish;
    end

    initial begin
        #100000;
        $display("[ERROR] Timeout");
        $finish;
    end

endmodule