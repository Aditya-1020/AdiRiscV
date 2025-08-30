`timescale 1ps/1ps
import isa_defs::*;

module data_memory (
    input logic clk,
    input logic [XLEN-1:0] address,
    input logic WriteEnable,
    input logic [XLEN-1:0] WriteData,
    output logic [XLEN-1:0] ReadData
);

    logic [XLEN-1:0] data_mem [0:MEM_SIZE-1];

    logic [9:0] word_address;

    always_ff @(posedge clk) begin
        if (WriteEnable) begin
            data_mem[word_address] <= WriteData;
        end        
    end

    assign ReadData = data_mem[word_address];

endmodule