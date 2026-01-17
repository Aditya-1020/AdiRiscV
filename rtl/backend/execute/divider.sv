import riscv_pkg::*;

module divider(
    input logic clk,
    input logic reset,
    input logic start,
    input logic is_signed,
    input logic is_rem,
    input logic [XLEN-1:0] dividend,
    input logic [XLEN-1:0] divisor,
    output logic [XLEN-1:0] result,
    output logic done,
    output logic busy
);
    timeunit 1ns;
    timeprecision 1ps;

    
endmodule