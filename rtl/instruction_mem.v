`timescale 1ps/1ps
`default_nettype none
`include "rtl/isa.vh"

module instruction_mem (
    input wire clk,
    input wire reset,
    input wire [`WORD_ADDRESS-1:0] address,
    output reg [`XLEN-1:0] instruction
);

    reg [`XLEN-1:0] instruction_memory [0:`MEM_SIZE-1];

    initial begin
        integer i;

        for (i = 0; i < `MEM_SIZE; i = i + 1) begin
            instruction_memory[i] = `NOP_INSTRUCTION;
        end

        $readmemh("rtl/test.hex", instruction_memory);

        `ifndef SYNTHESIS
            $display("Instruction Memory Initialized");
            $display("Memory size: %0d words", `MEM_SIZE);
            $display("First 4 instructions:");
            for (i = 0; i < 4 && i < `MEM_SIZE; i = i + 1) begin
                $display("  [%0d] = 0x%h", i, instruction_memory[i]);
            end
        `endif
    end

    always @(posedge clk) begin
        if (reset) begin
            instruction <= `NOP_INSTRUCTION;
        end else begin
            if (address < `MEM_SIZE)
                instruction <= instruction_memory[address];
            else
                instruction <= `NOP_INSTRUCTION;
        end
    end

    `ifndef SYNTHESIS
    always @(posedge clk) begin
        if (!reset && address >= `MEM_SIZE) begin
            $warning("out of bound instruction fetch: address = 0x%h, max = 0x%h", address, `MEM_SIZE);
        end
    end
    `endif
    
endmodule