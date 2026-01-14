import riscv_pkg::*;

module tb_single_cycle;

    timeunit 1ns;
    timeprecision 1ps;

    logic clk;
    logic reset;

    riscv_single_cycle_core dut (
        .clk(clk),
        .reset(reset)
    );

    initial clk = 0;
    always #5 clk = ~clk; // 100mhz

    function logic [XLEN-1:0] encode_r_type(
        input logic [6:0] opcode,
        input logic [4:0] rd, rs1, rs2,
        input logic [2:0] funct3,
        input logic [6:0] funct7
    );
        return {funct7, rs2, rs1, funct3, rd, opcode};
    endfunction

    function logic [XLEN-1:0] encode_i_type(
        input logic [6:0] opcode,
        input logic [4:0] rd, rs1,
        input logic [2:0] funct3,
        input logic [11:0] imm
    );
        return {imm, rs1, funct3, rd, opcode};
    endfunction

    function logic [XLEN-1:0] encode_s_type(
        input logic [6:0] opcode,
        input logic [4:0] rs1, rs2,
        input logic [2:0] funct3,
        input logic [11:0] imm
    );
        return {imm[11:5], rs2, rs1, funct3, imm[4:0], opcode};
    endfunction

    function logic [XLEN-1:0] encode_b_type(
        input logic [6:0] opcode,
        input logic [4:0] rs1, rs2,
        input logic [2:0] funct3,
        input logic [12:0] imm
    );
        return {imm[12], imm[10:5], rs2, rs1, funct3, imm[4:1], imm[11], opcode};
    endfunction

    function logic [XLEN-1:0] encode_u_type(
        input logic [6:0] opcode,
        input logic [4:0] rd,
        input logic [31:0] imm
    );
        return {imm[31:12], rd, opcode};
    endfunction

    function logic [XLEN-1:0] encode_j_type(
        input logic [6:0] opcode,
        input logic [4:0] rd,
        input logic [20:0] imm
    );
        return {imm[20], imm[10:1], imm[11], imm[19:12], rd, opcode};
    endfunction

    task automatic load_program();
        $display("\nLoading Test Program");
        
        dut.imem_inst.imem[0] = encode_i_type(OP_IMM, 5'd1, 5'd0, F3_ADD_SUB, 12'd5); // ADDI x1, x0, 5
        dut.imem_inst.imem[1] = encode_i_type(OP_IMM, 5'd2, 5'd0, F3_ADD_SUB, 12'd3); // ADDI x2, x0, 3
        dut.imem_inst.imem[2] = encode_r_type(OP_OP, 5'd3, 5'd1, 5'd2, F3_ADD_SUB, 7'h00); // ADD x3, x1, x2
        dut.imem_inst.imem[3] = encode_r_type(OP_OP, 5'd4, 5'd1, 5'd2, F3_ADD_SUB, F7_ALT); // SUB x4, x1, x2
        dut.imem_inst.imem[4] = encode_s_type(OP_STORE, 5'd0, 5'd3, F3_SW, 12'd0); // SW x3, 0(x0)
        dut.imem_inst.imem[5] = encode_i_type(OP_LOAD, 5'd5, 5'd0, F3_LW, 12'd0); // LW x5, 0(x0)
        dut.imem_inst.imem[6] = encode_b_type(OP_BRANCH, 5'd3, 5'd5, F3_BEQ, 13'd8); // BEQ x3, x5, 8
        dut.imem_inst.imem[7] = encode_i_type(OP_IMM, 5'd6, 5'd0, F3_ADD_SUB, 12'd99); // ADDI x6, x0, 99
        dut.imem_inst.imem[8] = encode_i_type(OP_IMM, 5'd7, 5'd0, F3_ADD_SUB, 12'd42); // ADDI x7, x0, 42
        dut.imem_inst.imem[9] = encode_u_type(OP_LUI, 5'd8, 32'h12345000); // LUI x8, 0x12345
        dut.imem_inst.imem[10] = encode_u_type(OP_AUIPC, 5'd9, 32'h01000000); // AUIPC x9, 0x1000
        dut.imem_inst.imem[11] = encode_j_type(OP_JAL, 5'd10, 21'd8); // JAL x10, 8
        dut.imem_inst.imem[12] = encode_i_type(OP_IMM, 5'd11, 5'd0, F3_ADD_SUB, 12'd88); // ADDI x11, x0, 88
        dut.imem_inst.imem[13] = encode_i_type(OP_IMM, 5'd12, 5'd0, F3_ADD_SUB, 12'd77); // ADDI x12, x0, 77
        
        // fill rest as NOPs
        for (int i = 14; i < IMEM_SIZE; i++) begin
            dut.imem_inst.imem[i] = NOP_INSTR;
        end
        $display("Program loaded");
    endtask

    task automatic monitor_regfile();
        $display("\nRegister File State");
        $display("Time: %0t, PC: 0x%08h", $time, dut.pc);
        for (int i = 0; i < 13; i++) begin
            if (dut.regfile_inst.registers[i] != 0) begin
                $display("x%-2d: 0x%08h (%0d)", i, dut.regfile_inst.registers[i], $signed(dut.regfile_inst.registers[i]));
            end
        end
    endtask

    task automatic verify_register(
        input int reg_num,
        input logic [XLEN-1:0] expected_value,
        input string test_name
    );
        logic [XLEN-1:0] actual_value;
        actual_value = dut.regfile_inst.registers[reg_num];
        
        if (actual_value == expected_value) begin
            $display("PASS: %s - x%0d = 0x%08h", test_name, reg_num, actual_value);
        end else begin
            $error("FAIL: %s - x%0d expected 0x%08h, got 0x%08h", test_name, reg_num, expected_value, actual_value);
        end
    endtask

    task automatic verify_memory(
        input logic [XLEN-1:0] addr,
        input logic [XLEN-1:0] expected_value,
        input string test_name
    );
        logic [XLEN-1:0] actual_value;
        logic [XLEN-1:0] word_addr;
        
        word_addr = {addr[XLEN-1:2], 2'b00};
        actual_value = {dut.dmem_inst.mem[word_addr+3], dut.dmem_inst.mem[word_addr+2], dut.dmem_inst.mem[word_addr+1], dut.dmem_inst.mem[word_addr]};
        
        if (actual_value == expected_value) begin
            $display("PASS: %s - mem[0x%08h] = 0x%08h", test_name, addr, actual_value);
        end else begin
            $error("FAIL: %s - mem[0x%08h] expected 0x%08h, got 0x%08h", test_name, addr, expected_value, actual_value);
        end
    endtask

    initial begin
        $dumpfile("riscv_single_cycle_core.vcd");
        $dumpvars(0, tb_single_cycle);
        
        $display("RISC-V Single-Cycle Core Test");
        
        reset = 1;
        
        load_program();
        
        // Reset
        @(posedge clk);
        @(posedge clk);
        reset = 0;
        
        $display("\Execution");
        
        repeat(20) begin
            @(posedge clk);
            #1; // reg update delay
            $display("\nCycle: PC=0x%08h, Instr=0x%08h", dut.pc, dut.instruction);
        end
        
        // final reg state
        monitor_regfile();
        
        $display("\nverification");
        verify_register(1, 32'd5, "ADDI x1");
        verify_register(2, 32'd3, "ADDI x2");
        verify_register(3, 32'd8, "ADD x3");
        verify_register(4, 32'd2, "SUB x4");
        verify_register(5, 32'd8, "LW x5");
        verify_register(6, 32'd0, "x6 should be 0 (skipped)");
        verify_register(7, 32'd42, "ADDI x7 (branch target)");
        verify_register(8, 32'h12345000, "LUI x8");
        verify_register(9, 32'h01000028, "AUIPC x9");
        verify_register(10, 32'h00000030, "JAL x10 (return addr)");
        verify_register(11, 32'd0, "x11 should be 0 (skipped)");
        verify_register(12, 32'd77, "ADDI x12 (JAL target)");
        verify_memory(32'h00000000, 32'd8, "SW x3 to mem[0]");
        
        $display("Test Complete");
        
        #100;
        $finish;
    end

    initial begin
        #10000;
        $error("TIMEOUT: Tb did not compile in time");
        $finish;
    end

endmodule