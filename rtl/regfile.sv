`timescale 1ps/1ps
import isa_defs::*;

module regfile (
    input logic clk, reset,
    // input logic regWrite,
    input logic regWriteEnabale,
    input logic [4:0] rs1, rs2, rd,
    input logic [XLEN-1:0] rd_data,
    output logic [XLEN-1:0] rs1_data,
    output logic [XLEN-1:0] rs2_data
);

    logic [XLEN-1:0] registers [0:XLEN-1];

    assign rs1_data = (rs1 == 5'b0) ? 32'b0 : registers[rs1];
    assign rs2_data = (rs2 == 5'b0) ? 32'b0 : registers[rs2];

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            for (int i = 0; i < XLEN; i++) begin
                registers[i] <= 32'b0;
            end
        end
        else if (regWriteEnabale && rd != 5'b0) begin
            registers[rd] <= rd_data;
        end
    end
    
endmodule