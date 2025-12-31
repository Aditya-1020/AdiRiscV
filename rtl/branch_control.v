`timescale 1ps/1ps
`default_nettype none
`include "rtl/isa.vh"

module branch_control (
    input wire [2:0] funct3,
    input wire [6:0] opcode,
    input wire alu_zero,
    input wire [31:0] rs1_data, rs2_data,
    input wire branch_enable,
    output reg branch_taken
);

    wire signed [31:0] rs1_signed = $signed(rs1_data);
    wire signed [31:0] rs2_signed = $signed(rs2_data);
    
    always @(*) begin
        branch_taken = 1'b0;
        if (branch_enable && opcode == `OP_B_TYPE) begin
            case (funct3)
                `FUNCT3_BEQ: branch_taken = (rs1_data == rs2_data);
                `FUNCT3_BNE: branch_taken = (rs1_data != rs2_data);
                `FUNCT3_BLT: branch_taken = (rs1_signed < rs2_signed);
                `FUNCT3_BGE: branch_taken = (rs1_signed >= rs2_signed);
                `FUNCT3_BLTU: branch_taken = (rs1_data < rs2_data);
                `FUNCT3_BGEU: branch_taken = (rs1_data >= rs2_data);
                default: branch_taken = 1'b0;
            endcase
        end
    end

endmodule