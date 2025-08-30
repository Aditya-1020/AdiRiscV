`timescale 1ps/1ps
import isa_defs::*;  // Import the package

module tb_instruction_mem;

    logic clk;
    logic [$clog2(MEM_SIZE)-1:0] address;
    logic [XLEN-1:0] instruction;

    instruction_memory dut (
        .clk(clk),
        .address(address),
        .instruction(instruction)
    );

    // 10 time units period
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Stimulus
    initial begin
        address = 0;
        repeat (8) begin
            @(posedge clk);
            $display("Time = %0t || address = %0d || Instruction = %h", $time, address, instruction);
            address = address + 1;  // increment
        end
        $finish;
    end

endmodule
