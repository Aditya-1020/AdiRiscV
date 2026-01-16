import riscv_pkg::*;

module tb_pipelined;

    timeunit 1ns;
    timeprecision 1ps;

    logic clk;
    logic reset;

    initial clk = 0;
    always #5 clk = ~clk; // 100mhz

    riscv_pipelined_core dut (
        .clk(clk),
        .reset(reset)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    task automatic load_hex(string filename);
        $readmemh(filename, dut.if_stage_inst.imem_inst.imem);
        $display("Loading rogram from hex %s", filename);
    endtask

    task automatic verify_loaded_program();
        $display("Verifying loadedprogram");
        for (int i= 0; i < 10; i++) begin
            if (dut.if_stage_inst.imem_inst.imem[i] != NOP_INSTR) begin // !NOP
                $display("imem[%0d] = 0x%08h", i, dut.if_stage_inst.imem_inst.imem[i]);
            end
        end
        $display("=========================\n");
    endtask

    task automatic run_cycles(int n);
        $display("Running %0d clk cycles", n);
        repeat(n) @(posedge clk);
        $display("completed %0d cycles",n);
    endtask

    task automatic display_registers();
        $display("\nRegfile state (time: %0t)", $time);
        $display("PC = 0x%08h", dut.if_stage_inst.pc_inst.pc);
        for (int i= 0; i < 32; i++) begin
            if(dut.id_stage_inst.regfile_inst.registers[i] != 0) begin
                $display("x%-2d: 0x%08h (%0d)",i, dut.id_stage_inst.regfile_inst.registers[i], 
                        $signed(dut.id_stage_inst.regfile_inst.registers[i]));
            end
        end
        $display("=================================\n");
    endtask


    task automatic chek_register(int reg_num, logic [XLEN-1:0] expected);
        logic [XLEN-1:0] actual;
        actual = dut.id_stage_inst.regfile_inst.registers[reg_num];

        if (actual == expected) begin
            $display("PASSSSSSSSS: x%0d = 0x%08h", reg_num, actual);
        end else begin
            $error("FAILL: x%0d expected = 0x%08h, got=0x%08h", reg_num, expected, actual);
        end
    endtask

    initial begin
        forever begin
            @(posedge clk);
            #1;
            if (!reset) begin
                $display("[%0t] PC=0x%02h | IF/ID=0x%08h | ID/EX.rd=x%0d | EX/MEM.rd=x%0d alu=0x%08h | MEM/WB.rd=x%0d | WB: x%0d←0x%08h (en=%b)", 
                    $time,
                    dut.if_stage_inst.pc_inst.pc,
                    dut.if_id_reg_out.instruction,
                    dut.id_ex_reg_out.rd_addr,
                    dut.ex_mem_out.rd_addr,
                    dut.ex_mem_out.alu_result,
                    dut.mem_wb_out.rd_addr,
                    dut.wb_rd_addr,
                    dut.wb_write_data,
                    dut.wb_reg_write);

                // $display("[%0t] Hazard: load_use=%b branch=%b | Stalls: pc=%b if_id=%b | Flushes: if_id=%b id_ex=%b", 
                $display("[%0t] Hazard:  branch=%b | Stalls: pc=%b if_id=%b | Flushes: if_id=%b id_ex=%b", 
                    $time,
                    // dut.hazard_unit_inst.load_use_hazard,
                    dut.branch_taken,
                    dut.pc_stall,
                    dut.if_id_stall,
                    dut.if_id_flush,
                    dut.id_ex_flush);
            
                $display("    Valid bits: if_id=%b id_ex=%b ex_mem=%b mem_wb=%b",
                    dut.if_id_reg_out.valid_if_id,
                    dut.id_ex_reg_out.valid_id_ex,
                    dut.ex_mem_out.valid_ex_mem,
                    dut.mem_wb_out.valid_mem_wb);
                
                $display("    Ctrl signals: reg_write=%b alu_op=%s",
                        dut.id_ex_reg_out.ctrl.reg_write,
                        dut.id_ex_reg_out.ctrl.alu_op.name());
            end
        end
    end

    initial begin
        $dumpfile("pipelined.vcd");
        $dumpvars(0, tb_pipelined);


        $display("\n========================================");
        $display("RISC-V Pipelined Core Testbench");
        $display("========================================\n");

        reset = 1;

        load_hex("programs/add.hex");
        verify_loaded_program();
        
        // reset seq
        $display("Applying reset");
        repeat(3) @(posedge clk);
        reset = 0;
        $display("Reset released\n");

        // Run program
        run_cycles(20);

        display_registers();

        $display("=== Verification ===");
        if (dut.id_stage_inst.regfile_inst.registers[1] == 32'd5)
            $display("✓ x1 = 5");
        else
            $error("✗ x1 = %0d (expected 5)", dut.id_stage_inst.regfile_inst.registers[1]);
            
        if (dut.id_stage_inst.regfile_inst.registers[2] == 32'd3)
            $display("✓ x2 = 3");
        else
            $error("✗ x2 = %0d (expected 3)", dut.id_stage_inst.regfile_inst.registers[2]);
            
        if (dut.id_stage_inst.regfile_inst.registers[3] == 32'd8)
            $display("✓ x3 = 8");
        else
            $error("✗ x3 = %0d (expected 8)", dut.id_stage_inst.regfile_inst.registers[3]);

        $display("\n TEST COOMPLETE");

        $finish;
    end

    initial begin
        #10000;
        $error("TIMEOUT: Tb did not compile in time");
        $finish;
    end


endmodule