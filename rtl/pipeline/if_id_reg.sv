import riscv_pkg::*;

module if_id_reg (
    input logic clk,
    input logic reset,
    input logic stall, // hold values
    input logic flush // insert bubble (NOP)
    input if_id_reg_t in,
    output if_id_reg_t out
);

    timeunit 1ns;
    timeprecision 1ps;

    
    always_ff @(posedge clk) begin
        if (reset || flush) begin
            // Insert NOP/bubble
            out.pc <= RESET_PC;
            out.instruction <= NOP_INSTR;
            out.pc_plus4 <= NOP_INSTR;
            out.valid_if_id <= 1'b0;
        end else if (!stall) begin
            out <= in;
        end
        // If stall=1 implicitly hold current values
    end

endmodule