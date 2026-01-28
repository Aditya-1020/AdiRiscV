import riscv_pkg::*;

module tb_tracex5;

    timeunit 1ns;
    timeprecision 1ps;

    logic clk;
    logic reset;

    initial clk = 0;
    always #5 clk = ~clk;

    riscv_pipelined_core dut (
        .clk(clk),
        .reset(reset)
    );

    // Track the x5 instruction through pipeline
    int x5_instr_cycle;
    logic [31:0] x5_instruction = 32'h00a00293; // addi x5, x0, 10

    always @(posedge clk) begin
        if (!reset) begin
            $display("\n=== Cycle %0d ===", ($time/10) - 5);
            
            // IF stage
            if (dut.if_id_out.instruction == x5_instruction) begin
                $display(">>> x5 instruction in IF/ID INPUT");
            end
            
            // IF/ID register
            if (dut.if_id_reg_out.instruction == x5_instruction) begin
                $display(">>> x5 instruction in IF/ID OUTPUT");
                $display("    valid_if_id = %b", dut.if_id_reg_out.valid_if_id);
                $display("    if_id_flush = %b", dut.if_id_flush);
            end
            
            // ID/EX register
            if (dut.id_ex_reg_out.rd_addr == 5'd5 && 
                dut.id_ex_reg_out.ctrl.reg_write == 1'b1) begin
                $display(">>> x5 instruction in ID/EX");
                $display("    rd_addr = %d", dut.id_ex_reg_out.rd_addr);
                $display("    rs1_data = 0x%08h", dut.id_ex_reg_out.rs1_data);
                $display("    rs2_data = 0x%08h", dut.id_ex_reg_out.rs2_data);
                $display("    immediate = 0x%08h", dut.id_ex_reg_out.immediate);
                $display("    alu_op = %s", dut.id_ex_reg_out.ctrl.alu_op.name());
                $display("    alu_src = %b", dut.id_ex_reg_out.ctrl.alu_src);
                $display("    reg_write = %b", dut.id_ex_reg_out.ctrl.reg_write);
                $display("    valid_id_ex = %b", dut.id_ex_reg_out.valid_id_ex);
            end
            
            // EX/MEM register
            if (dut.ex_mem_out.rd_addr == 5'd5 && 
                dut.ex_mem_out.ctrl.reg_write == 1'b1) begin
                $display(">>> x5 instruction in EX/MEM");
                $display("    rd_addr = %d", dut.ex_mem_out.rd_addr);
                $display("    alu_result = 0x%08h", dut.ex_mem_out.alu_result);
                $display("    reg_write = %b", dut.ex_mem_out.ctrl.reg_write);
                $display("    valid_ex_mem = %b", dut.ex_mem_out.valid_ex_mem);
            end
            
            // MEM/WB register
            if (dut.mem_wb_out.rd_addr == 5'd5 && 
                dut.mem_wb_out.ctrl.reg_write == 1'b1) begin
                $display(">>> x5 instruction in MEM/WB");
                $display("    rd_addr = %d", dut.mem_wb_out.rd_addr);
                $display("    alu_result = 0x%08h", dut.mem_wb_out.alu_result);
                $display("    mem_data = 0x%08h", dut.mem_wb_out.mem_data);
                $display("    mem_to_reg = %b", dut.mem_wb_out.ctrl.mem_to_reg);
                $display("    reg_write = %b", dut.mem_wb_out.ctrl.reg_write);
                $display("    valid_mem_wb = %b", dut.mem_wb_out.valid_mem_wb);
            end
            
            // WB stage outputs
            if (dut.wb_reg_write && dut.wb_rd_addr == 5'd5) begin
                $display(">>> WB WRITING TO x5!");
                $display("    wb_rd_addr = %d", dut.wb_rd_addr);
                $display("    wb_write_data = 0x%08h", dut.wb_write_data);
                $display("    wb_reg_write = %b", dut.wb_reg_write);
            end
            
            // Show ALL WB writes
            if (dut.wb_reg_write) begin
                $display("WB: x%0d = 0x%08h", dut.wb_rd_addr, dut.wb_write_data);
            end
            
            // Show register file state for x5
            $display("Register x5 current value = 0x%08h", 
                    dut.id_stage_inst.regfile_inst.registers[5]);
        end
    end

    initial begin
        $dumpfile("trace_x5.vcd");
        $dumpvars(0, tb_tracex5);

        $display("\n╔═══════════════════════════════════════╗");
        $display("║  Trace x5 Instruction                  ║");
        $display("╚═══════════════════════════════════════╝");

        reset = 1;
        
        // Load program
        $readmemh("programs/TEST.hex", dut.mem_ctrl.imem);
        $display("[INFO] Program loaded");
        $display("[INFO] First instruction = 0x%08h (should be 0x00a00293)", 
                dut.mem_ctrl.imem[0]);

        repeat(5) @(posedge clk);
        reset = 0;
        $display("\n[INFO] Starting execution...\n");

        // Run until x5 should be written
        repeat(15) @(posedge clk);

        $display("\n╔═══════════════════════════════════════╗");
        $display("║  Final Check                           ║");
        $display("╚═══════════════════════════════════════╝");
        $display("x5 = 0x%08h (expected 0x0000000a)", 
                dut.id_stage_inst.regfile_inst.registers[5]);
        $display("x6 = 0x%08h (expected 0x00000014)", 
                dut.id_stage_inst.regfile_inst.registers[6]);
        $display("x7 = 0x%08h (expected 0x0000001e)", 
                dut.id_stage_inst.regfile_inst.registers[7]);

        $finish;
    end

    initial begin
        #10000;
        $display("[ERROR] Timeout");
        $finish;
    end

endmodule