`timescale 1ps/1ps
`default_nettype none
`include "rtl/isa.vh"

module pc (
    input wire clk,
    input wire reset,
    input wire pc_en,
    input wire [`XLEN-1:0] pc_next,
    output reg [`XLEN-1:0] pc
);

    always @(posedge clk) begin
        if (reset)
            pc <= `RESET_PC;
        else if (pc_en)
            pc <= pc_next;
     // else implicityl hold pc
    end
    
endmodule