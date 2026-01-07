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
        input string name,
        input logic [XLEN-1:0] expected
    );
        #1;
        if (immediate == expected) begin
            $display("PASS: %s expected: %h, got: %h", name, expected, immediate);
            pass_count++;
        end else begin
            $display("FAIL: %s expected: %h, got: %h", name, expected, immediate);
            fail_count++;
        end
    endtask

    initial begin
        $dumpfile("imm_gen.vcd");
        $dumpvars(0, tb_imm_gen);

        $display("Imm gen tb\n");

        $display("format: instruction = {imm, rd, funct3, rs1, opcode}; \n");

        $display("\nI type");
        // positive immediate
        instruction = {12'h123, 5'd1, 3'b000, 5'd2, OP_IMM};
        check_imm("positive immediate", 32'h00000123);

        // negative immediate
        instruction = {12'hFFF, 5'd1, 3'b000, 5'd2, OP_IMM};
        check_imm("negative immediate", 32'hFFFFFFFF);

        // zero immediate
        instruction = {12'h000, 5'd1, 3'b000, 5'd2, OP_IMM};
        check_imm("zero", 32'h00000000);

        // max positive
        instruction = {12'h7FF, 5'd1, 3'b000, 5'd2, OP_LOAD};
        check_imm("max pos",32'h000007FF);

        // min negative
        instruction = {12'h800, 5'd1, 3'b000, 5'd2, OP_JALR};
        check_imm("min neg",32'hFFFFF800);

        // S-TYPE
        $display("\n\nS type");

        // positive immediate
        instruction = {7'h09, 5'd2, 5'd1, 3'b010, 5'h0A, OP_STORE};
        check_imm("pos imm",32'h0000012A);

        // negative immediate
        instruction = {7'h7F, 5'd2, 5'd1, 3'b010, 5'h1F, OP_STORE};
        check_imm("neg imm",32'hFFFFFFFF);

        // zero
        instruction = {7'h00, 5'd2, 5'd1, 3'b010, 5'h00, OP_STORE};
        check_imm("zero", 32'h00000000);

        $display("\n\nB type");
        
        // psotive brach offset (forwadrd)
        instruction = {1'b0, 6'b0, 5'd2, 5'd1, 3'b000, 4'b0100, 1'b0, OP_BRANCH};
        check_imm("pos branch (fwd)",32'h00000008);

        // negative branch offset (backward)
        instruction = {1'b1, 6'b111111, 5'd2, 5'd1, 3'b000, 4'b1111, 1'b1, OP_BRANCH};
        check_imm("neg branch (bwd)", 32'hFFFFFFFE);

        // zero offset
        instruction = {1'b0, 6'b0, 5'd2, 5'd1, 3'b0, 4'b0, 1'b0, OP_BRANCH};
        check_imm("zero offset",32'h00000000);

        $display("\n\nU type");
        
        // lui upper
        instruction = {20'h12345, 5'd1, OP_LUI};
        check_imm("lui ipper",32'h12345000);

        // AUIPC upperr
        instruction = {20'hFFFFF, 5'd1, OP_AUIPC};
        check_imm("auipc upper", 32'hFFFFF000);

        // zero
        instruction = {20'h00000, 5'd1, OP_LUI};
        check_imm("zero", 32'h00000000);

        $display("\n\nJ type");
        // positive jump offset
        instruction = {1'b0, 10'b0000000010, 1'b0, 8'b0, 5'd1, OP_JAL};
        check_imm("pos jump offset",32'h00000004);

        // zero
        instruction = {1'b0, 10'b0, 1'b0, 8'b0, 5'd1, OP_JAL};
        check_imm("zero", 32'h00000000);

        // larger positive offest
        instruction = {1'b0, 10'b0000010000, 1'b0, 8'b0, 5'd1, OP_JAL};
        check_imm("larger pos offset", 32'h00000020);

        $display("\n\nEdge cases");
        instruction = 32'hFFFFFFFF;
        instruction[6:0] = 7'b1111111;
        check_imm("edge cases",32'h00000000);

        // results
        #10;
        $display("\nTest summary");
        $display("passd: %0d", pass_count);
        $display("failed: %0d", fail_count);
        $display("total: %0d", pass_count + fail_count);
        if (fail_count == 0)
            $display("\nall test passed");
        else
            $display("\nsome test failed");

        $finish;
    end


    initial begin
        #10000;
        $error("TIMEOUT: Tb did not compile in time");
        $finish;
    end

endmodule