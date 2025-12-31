`timescale 1ps/1ps
`default_nettype none
`include "rtl/isa.vh"

module regfile (
    input wire clk,
    input wire reset,
    input wire [4:0] rs1_addr,
    input wire [4:0] rs2_addr,
    input wire [4:0] rd,
    input wire [`XLEN-1:0] write_data,
    input wire wr_en,
    output wire [`XLEN-1:0] rs1_data,
    output wire [`XLEN-1:0] rs2_data
);

    reg [`XLEN-1:0] registers [0:`NUM_REGS-1];

    assign rs1_data = (rs1_addr == 5'b0) ? 32'b0 : registers[rs1_addr];
    assign rs2_data = (rs2_addr == 5'b0) ? 32'b0 : registers[rs2_addr];
    
    integer i;
    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < `NUM_REGS; i = i + 1) begin
                registers[i] <= 32'b0;
            end
        end
        else if (wr_en && rd != 5'b0) begin
            registers[rd] <= write_data;
        end
    end

endmodule