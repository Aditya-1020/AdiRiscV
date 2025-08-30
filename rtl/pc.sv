// Program Counter
`timescale 1ps/1ps
import isa_defs::*;

module PC (
    input  logic clk,
    input  logic reset,
    input  logic [XLEN-1:0] pc_in, // pc_next
    output logic [XLEN-1:0] pc // pc
);

    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            pc <= 32'h0;
        else
            pc <= pc_in;
    end

endmodule