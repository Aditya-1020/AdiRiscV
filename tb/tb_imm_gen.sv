import riscv_pkg::*;

module tb_imm_gen;
    timeunit 1ns;
    timeprecision 1ps;
    
    logic [XLEN-1:0] immediate;
    logic [XLEN-1:0] instruction;

    int pass_count = 0;
    int fail_count = 0;
    
    imm_gen dut (
        .instruction(instruction),
        .immediate(immediate)
    );

    task automatic check_imm(
        input logic [XLEN-1:0] expected
    );
        #1;
        if (immediate == expected) begin
            $display("PASS: expected: %h, got: %h",expected, immediate);
            pass_count++;
        end else begin
            $error("FAIL: expected: %h, got: %h", expected, immediate);
            fail_count++;
        end
    endtask

    function automatic logic [XLEN-1:0] build_instruction(
        input logic [6:0] opcode,
        input logic [4:0] rd,
        input logic [2:0] funct3,
        input logic [2:0] rs1,
        input logic [4:0] rs2,
        input logic [6:0] funct7
    );
        return {funct7, rs2, rs1, funct3, rd, opcode};

    endfunction

    initial begin
        $dumpfile("imm_gen.vcd");
        $dumpvars(0, tb_imm_gen);

        $display("Imm gen tb\n");

        $display("\nI type");
        // positive immediate
        instruction = {12'h123, 5'd1, 3'b000, 5'd2, OP_IMM};
        check_imm(32'h00000123);
        
        // negative immediate
        instruction = {12'hFF, 5'd1, 3'b000, 5'd2, OP_IMM};
        check_imm(32'hFFFFFFFF);

        // zero immediate
        instruction = {12'h000, 5'd1, 3'b000, 5'd2, OP_IMM};
        check_imm(32'h00000000);

        // max positive
        instruction = {12'hFF, 5'd1, 3'b000, 5'd2, OP_LOAD};
        check_imm(32'h000007FF);

        // min negative
        instruction = {12'h800, 5'd1, 3'b000, 5'd2, OP_JALR};
        check_imm(32'hFFFFF800);

        // S-TYPE
        $display("\nS type");

        // positive immediate
        instruction = {7'h09, 5'd2, 5'd1, 3'b010, 5'h0A, OP_STORE};
        check_imm(32'h0000012A);

        // negative immediate
        instruction = {7'hF, 5'd2, 5'd1, 3'b010, 5'h1F, OP_STORE};
        check_imm(32'hFFFFFFFF);

        // zero
        instruction = {7'h00, 5'd2, 5'd1, 3'b010, 5'h00, OP_STORE};
        check_imm(32'h00000000);

        $display("\nB type");
        
        // psotive brach offset (forwadrd)
        instruction = {1'b0, 6'b0, 5'd2, 5'd1, 3'b000, 4'b0100, 1'b0, OP_BRANCH};
        check_imm(32'h00000008);

        // negative branch offset (backward)
        instruction = {1'b1, 6'b1, 5'd2, 5'd1, 3'b000, 4'b1, 1'b1, OP_BRANCH};
        check_imm(32'hFFFFFFFE);

        // zero offset
        instruction = {1'b0, 6'b0, 5'd2, 5'd1, 3'b0, 4'b0, 1'b0, OP_BRANCH};
        check_imm(32'h00000000);

        $display("\nU type");
        
        // lui upper
        instruction = {20'h12345, 5'd1, OP_LUI};
        check_imm(32'h12345000);

        // AUIPC upperr
        instruction = {20'hFFFFF, 5'd1, OP_AUIPC};
        check_imm(32'hFFFFF000);

        // zero
        instruction = {20'h00000, 5'd1, OP_LUI};
        check_imm(32'h00000000);

        $display("\nJ type");
        // positive jump offset
        instruction = {1'b0, 10'b0000000010, 1'b0, 8'b0, 5'd1, OP_JAL};
        check_imm(32'h00000004);

        // zero
        instruction = {1'b0, 10'b0, 1'b0, 8'b0, 5'd1, OP_JAL};
        check_imm(32'h00000000);

        // larger positive offest
        instruction = {1'b0, 10'b0000010000, 1'b0, 8'b0, 5'd1, OP_JAL};
        check_imm(32'h00000020);

        $display("Edge cases");
        instruction = 32'hFFFFFFFF;
        instruction[6:0] = 7'b1111111;
        check_imm(32'h00000000);

        // Resutls
        #10;
        $display("\nTest summary");
        $display("passd: %0d", pass_count);
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
        $error("TIMEOUT: Tb did not compile in time");
        $finish;
    end

endmodule