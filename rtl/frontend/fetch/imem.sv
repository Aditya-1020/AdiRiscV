import riscv_pkg::*;

module imem(
    input logic [WORD_ADDR_WIDTH-1:0] address, // word addressed
    output logic [XLEN-1:0] instruction
);
    timeunit 1ns; timeprecision 1ps;

    logic [XLEN-1:0] imem [0:IMEM_SIZE-1];

    //NOTE: you can use (* ramstyle = "block" *) logic [XLEN-1:0] mem[0:IMEM_SIZE-1]; // for fpga later

    // combination read -- NOTE: more preffered
    /*
    always_comb begin
        if (address < IMEM_SIZE) begin
            instruction = imem[address];
        end else begin
            instruction = NOP_INSTR;
        end
    end
    */
    /*
    NOTE:
    - direct assigns better since address < IMEM_SIZE is always true and renders the else as unusable
    */
    assign instruction = imem[address];
    
endmodule