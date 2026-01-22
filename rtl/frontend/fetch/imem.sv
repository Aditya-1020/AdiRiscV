import riscv_pkg::*;

module imem(
    input logic clk,
    input logic [WORD_ADDR_WIDTH-1:0] address, // word addressed
    output logic [XLEN-1:0] instruction
);
    timeunit 1ns; timeprecision 1ps;

    (* ram_style = "block" *) logic [XLEN-1:0] imem [0:IMEM_SIZE-1];
    
    // logic [XLEN-1:0] imem [0:IMEM_SIZE-1];

    logic [XLEN-1:0] instruction_reg;

    // sychronous read forBRAM interface
    always_ff @(posedge clk) begin
        if (address < IMEM_SIZE) begin
            instruction_reg <= imem[address];
        end else begin
            instruction_reg <= NOP_INSTR;
        end
    end

    /*
    NOTE: Tried doing combination read but 
        - direct assigns better since address < IMEM_SIZE is always true and renders the else as unusable
    */
    assign instruction = instruction_reg;

    // INitialize for BRAM
    initial begin
        for (int i = 0; i < IMEM_SIZE; i++) begin
            imem[i] = NOP_INSTR;
        end
    end
    
endmodule