`timescale 1ps/1ps

module regfile (#parameter WIDTH = 32;) (
    input logic clk,
    input logic reset,
    input logic [4:0] rs1,
    input logic [4:0] rs2,
    input logic [4:0] rd,
    input logic [WIDTH-1:0] wd, // write data
    input logic we, // weite enable
    output logic [WIDTH-1:0] rd1,
    output logic [WIDTH-1:0] rd2,
);

logic [WIDTH-1:0] registers [0:WIDTH-1];

always_ff @(posedge ck or posedge reset) begin
    if (reset) begin
        for (int i = 0; i < 32; i++)
            registers[i] <= 32'b0;
        end
        else if (we && rd != 5'b0) begin
            registers[rd] <= wd;
        end
end
    
assign rd1 = (rs1 == 5'b0) ? 32'b0 : registers[rs1];
assign rd2 = (rs2 == 5'b0) ? 32'b0 : registers[rs2];

endmodule