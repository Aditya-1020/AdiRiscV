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

    // Monitor signals every cycle
    always @(posedge clk) begin
        if (!reset) begin
            $display("\n=== Cycle %0d (time %0t) ===", $time/10, $time);
            $display("PC = 0x%08h", dut.if_stage_inst.pc);
            $display("IMEM addr = 0x%08h", dut.imem_addr);
            $display("Instruction = 0x%08h", dut.imem_rdata);
            $display("IF/ID.valid = %b", dut.if_id_reg_out.valid_if_id);
            $display("IF/ID.instruction = 0x%08h", dut.if_id_reg_out.instruction);
            $display("ID/EX.valid = %b", dut.id_ex_reg_out.valid_id_ex);
            $display("EX/MEM.valid = %b", dut.ex_mem_out.valid_ex_mem);
            $display("MEM/WB.valid = %b", dut.mem_wb_out.valid_mem_wb);
            
            // Check hazards
            $display("Hazards: pc_stall=%b, if_id_flush=%b, id_ex_flush=%b, ex_stall=%b",
                    dut.pc_stall, dut.if_id_flush, dut.id_ex_flush, dut.ex_stall);
            
            // Check WB
            if (dut.wb_reg_write) begin
                $display("WB: Writing x%0d = 0x%08h", dut.wb_rd_addr, dut.wb_write_data);
            end
        end
    end

    task automatic load_program();
        $readmemh("programs/TEST.hex", dut.mem_ctrl.imem);
        $display("\n[INFO] Program loaded");
        
        // Verify first few instructions
        $display("\nFirst 10 instructions:");
        for (int i = 0; i < 10; i++) begin
            $display("  imem[%0d] = 0x%08h", i, dut.mem_ctrl.imem[i]);
        end
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
        $dumpfile("pipelined_debug.vcd");
        $dumpvars(0, tb_pipelined);

        $display("\n╔═══════════════════════════════════════╗");
        $display("║  Pipeline Debug Test                  ║");
        $display("╚═══════════════════════════════════════╝");

        reset = 1;
        load_program();

        $display("\n[INFO] Holding reset for 5 cycles...");
        repeat(5) @(posedge clk);
        
        reset = 0;
        $display("\n[INFO] Reset released, starting execution...");

        // Run for limited cycles with monitoring
        repeat(30) @(posedge clk);

        $display("\n\n╔═══════════════════════════════════════╗");
        $display("║  Final Register State                 ║");
        $display("╚═══════════════════════════════════════╝");
        
        for (int i = 0; i < 32; i++) begin
            if (dut.id_stage_inst.regfile_inst.registers[i] != 0) begin
                $display("  x%-2d = 0x%08h (%0d)", i,
                        dut.id_stage_inst.regfile_inst.registers[i],
                        $signed(dut.id_stage_inst.regfile_inst.registers[i]));
            end
        end

        $display("\n╔═══════════════════════════════════════╗");
        $display("║  Expected Results                     ║");
        $display("╚═══════════════════════════════════════╝");
        
        check_reg(5,  32'd10, "x5 = 10");
        check_reg(6,  32'd20, "x6 = 20");
        check_reg(7,  32'd30, "x7 = 30");

        $finish;
    end

    initial begin
        #50000;
        $display("\n[ERROR] Timeout");
        $finish;
    end

endmodule