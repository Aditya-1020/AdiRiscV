import riscv_pkg::*;

module pc(
    input logic clk,
    input logic reset,
    input logic pc_en,
    input logic [XLEN-1:0] pc_next,
    output logic [XLEN-1:0] pc
);
    timeunit 1ns;
    timeprecision 1ps;

    always_ff @(posedge clk) begin
        if (reset) begin
            pc <= RESET_PC;
        end else if (pc_en) begin
            pc <= pc_next;
        end
    end

endmodule