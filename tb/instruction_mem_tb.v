`timescale 1ps/1ps
`default_nettype none
`include "rtl/isa.vh"

module instruction_mem_tb;
    localparam WORD_ADDRESS = `WORD_ADDRESS;
    localparam XLEN = `XLEN;
    localparam MEM_SIZE = `MEM_SIZE;
    localparam NOP_INSTRUCTION = `NOP_INSTRUCTION;

    reg clk;
    reg reset;
    reg [WORD_ADDRESS-1:0] address;
    wire [XLEN-1:0] instruction;

    integer pass_count = 0;
    integer fail_count = 0;

    instruction_mem instruction_mem_dut (
        .clk(clk),
        .reset(reset),
        .address(address),
        .instruction(instruction)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("instruction_mem_tb.vcd");
        $dumpvars(0, instruction_mem_tb);
    end

    task check_instruction;
        input [WORD_ADDRESS-1:0] addr;
        input [XLEN-1:0] expected;
        input [200*8-1:0] test_name;
        reg [XLEN-1:0] captured_instr;
        begin
            address = addr;
            @(posedge clk);
            @(posedge clk);
            #1;
            captured_instr = instruction;

            if (captured_instr == expected) begin
                $display("PASS: %0s - addr=%0d, instr=0x%h", test_name, addr, captured_instr);
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: %0s - addr=%0d, expected=0x%h, got=0x%h", test_name, addr, expected, captured_instr);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        reset = 1;
        address = 0;

        repeat(3) @(posedge clk);
        reset = 0;
        @(posedge clk);

        $display("start test\n");

        check_instruction(0, 32'h00000093, "first");
        check_instruction(1, 32'h00500113, "second");
        check_instruction(2, 32'h00a00193, "third");
        check_instruction(3, 32'h002081b3, "fourth");

        check_instruction(10, 32'h00000513, "jump addr 10");
        check_instruction(5, 32'h002122b3, "jump addr 5");
        check_instruction(0, 32'h00000093, "first addr again");
        check_instruction(MEM_SIZE-1, NOP_INSTRUCTION, "last valid addr");
    
        // check_instruction(MEM_SIZE, NOP_INSTRUCTION, "out of bounds 1st invalid");
        check_instruction(MEM_SIZE+100, NOP_INSTRUCTION, "out of bounds far invalid");

        $display("\ntest for reset");
        address = 0;
        reset = 1;
        @(posedge clk);
        @(posedge clk);
        if (instruction == NOP_INSTRUCTION) begin
            $display("PASS: reset pass");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: reset fail, got=0x%h", instruction);
            fail_count = fail_count + 1;
        end
        
        reset = 0;

        @(posedge clk);
        $display("\n=== Test Summary ===");
        $display("Total tests: %0d", pass_count + fail_count);
        $display("Passed: %0d", pass_count);
        $display("Failed: %0d", fail_count);
        
        if (fail_count == 0)
            $display("\n*** ALL TESTS PASSED ***\n");
        else
            $display("\n*** SOME TESTS FAILED ***\n");

        #100;
        $finish;
        
    end

    initial begin
        #50000;
        $display("ERROR: Timeout");
        $finish;
    end

endmodule