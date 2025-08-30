`timescale 1ps/1ps
import isa_defs::*;

module instruction_mem (
    // input logic clk
    input logic [XLEN-1:0] address,
    output logic [XLEN-1:0] instruction
);

    logic [XLEN-1:0] inst_mem [0:MEM_SIZE-1];

    
    initial begin
        $readmemh("rtl/memory.hex", mem);
    end

    // read
    // always_ff @(posedge clk) begin
        // instruction <= mem[address];
    // end


    assign instruction = inst_mem[address[XLEN-1:2]];

endmodule