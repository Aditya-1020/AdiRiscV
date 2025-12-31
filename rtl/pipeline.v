`timescale 1ps/1ps
`default_nettype none
`include "rtl/isa.vh"

module IF_ID_reg (
    input wire clk,
    input wire reset,
    input wire stall,
    input wire flush,
    input [`XLEN-1:0] pc_in,
    input [`XLEN-1:0] instruction_in,
    input wire prediction_in,
    input [`XLEN-1:0] predicted_target_in,

    output reg [`XLEN-1:0] pc_out,
    output reg [`XLEN-1:0] instruction_out,
    output reg prediction_out,
    output reg [`XLEN-1:0] predicted_target_out
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc_out <= `RESET_PC;
            instruction_out <= `NOP_INSTRUCTION;
            prediction_out <= 1'b0;
            predicted_target_out <= 32'b0;
        end else if (flush) begin
            pc_out <= `RESET_PC;
            instruction_out <= `NOP_INSTRUCTION;
            prediction_out <= 1'b0;
            predicted_target_out <= 32'b0;
        end else if (!stall) begin
            pc_out <= pc_in;
            instruction_out <= instruction_in;
            prediction_out <= prediction_in;
            predicted_target_out <= predicted_target_in;
        end
    end

endmodule

module ID_EX_reg (
    input wire clk,
    input wire reset,
    input wire flush,
    input wire stall,

    input wire RegWrite_in, MemToReg_in, MemWrite_in, MemRead_in,
    input wire ALUSrc_in, branch_in,
    input wire [3:0] ALU_op_in,
    input wire is_jal_in, is_jalr_in, is_branch_in,

    input wire [`XLEN-1:0] pc_in,
    input wire [`XLEN-1:0] rs1_data_in, rs2_data_in,
    input wire [`XLEN-1:0] immediate_in,
    
    input wire [4:0] rs1_addr_in, rs2_addr_in, rd_addr_in,
    input wire [2:0] funct3_in,
    input wire [6:0] opcode_in,
    input wire instr_30_in,

    input wire prediction_in,
    input wire [`XLEN-1:0] predicted_target_in,

    output reg RegWrite_out, MemToReg_out, MemWrite_out, MemRead_out,
    output reg ALUSrc_out, branch_out,
    output reg [3:0] ALU_op_out,
    output reg is_jal_out, is_jalr_out, is_branch_out,

    output reg [`XLEN-1:0] pc_out,
    output reg [`XLEN-1:0] rs1_data_out, rs2_data_out,
    output reg [`XLEN-1:0] immediate_out,

    output reg [4:0] rs1_addr_out, rs2_addr_out, rd_addr_out,
    output reg [2:0] funct3_out,
    output reg [6:0] opcode_out,
    output reg instr_30_out,

    output reg prediction_out,
    output reg [`XLEN-1:0] predicted_target_out
);

    always @(posedge clk or posedge reset) begin
        if (reset || flush) begin
            RegWrite_out <= 1'b0;
            MemToReg_out <= 1'b0;
            MemWrite_out <= 1'b0;
            MemRead_out <= 1'b0;
            ALUSrc_out <= 1'b0;
            branch_out <= 1'b0;
            ALU_op_out <= 4'b0;
            is_jal_out <= 1'b0;
            is_jalr_out <= 1'b0;
            is_branch_out <= 1'b0;
            pc_out <= `RESET_PC;
            rs1_data_out <= 32'b0;
            rs2_data_out <= 32'b0;
            immediate_out <= 32'b0;
            rs1_addr_out <= 5'b0;
            rs2_addr_out <= 5'b0;
            rd_addr_out <= 5'b0;
            funct3_out <= 3'b0;
            opcode_out <= 7'b0;
            instr_30_out <= 1'b0;
            prediction_out <= 1'b0;
            predicted_target_out <= 32'b0;
        end else if (!stall) begin
            RegWrite_out <= RegWrite_in;
            MemToReg_out <= MemToReg_in;
            MemWrite_out <= MemWrite_in;
            MemRead_out <= MemRead_in;
            ALUSrc_out <= ALUSrc_in;
            branch_out <= branch_in;
            ALU_op_out <= ALU_op_in;
            is_jal_out <= is_jal_in;
            is_jalr_out <= is_jalr_in;
            is_branch_out <= is_branch_in;
            pc_out <= pc_in;
            rs1_data_out <= rs1_data_in;
            rs2_data_out <= rs2_data_in;
            immediate_out <= immediate_in;
            rs1_addr_out <= rs1_addr_in;
            rs2_addr_out <= rs2_addr_in;
            rd_addr_out <= rd_addr_in;
            funct3_out <= funct3_in;
            opcode_out <= opcode_in;
            instr_30_out <= instr_30_in;
            prediction_out <= prediction_in;
            predicted_target_out <= predicted_target_in;
        end
    end

endmodule

module EX_MEM_reg (
    input wire clk,
    input wire reset,
    input wire stall,
    input wire flush,
    
    input wire [`XLEN-1:0] alu_result_in,
    input wire [`XLEN-1:0] rs2_data_in,
    input wire RegWrite_in, MemToReg_in, MemRead_in, MemWrite_in,
    input wire branch_in,
    input wire [4:0] rd_addr_in,
    input wire [2:0] funct3_in,
    input wire [`XLEN-1:0] branch_target_in,
    input wire branch_taken_in,
    
    output reg [`XLEN-1:0] alu_result_out, rs2_data_out,
    output reg RegWrite_out, MemToReg_out, MemWrite_out, MemRead_out,
    output reg branch_out,
    output reg [4:0] rd_addr_out,
    output reg [2:0] funct3_out,
    output reg [`XLEN-1:0] branch_target_out,
    output reg branch_taken_out
);

    always @(posedge clk or posedge reset) begin
        if (reset || flush) begin
            alu_result_out <= 32'b0;
            rs2_data_out <= 32'b0;
            RegWrite_out <= 1'b0;
            MemToReg_out <= 1'b0;
            MemWrite_out <= 1'b0;
            MemRead_out <= 1'b0;
            branch_out <= 1'b0;
            rd_addr_out <= 5'b0;
            funct3_out <= 3'b0;
            branch_target_out <= 32'b0;
            branch_taken_out <= 1'b0;
        end else if (!stall) begin
            alu_result_out <= alu_result_in;
            rs2_data_out <= rs2_data_in;
            RegWrite_out <= RegWrite_in;
            MemToReg_out <= MemToReg_in;
            MemWrite_out <= MemWrite_in;
            MemRead_out <= MemRead_in;
            branch_out <= branch_in;
            rd_addr_out <= rd_addr_in;
            funct3_out <= funct3_in;
            branch_target_out <= branch_target_in;
            branch_taken_out <= branch_taken_in;
        end
    end

endmodule

module MEM_WB_reg (
    input wire clk,
    input wire reset,
    input wire stall,
    input wire flush,
    input wire [`XLEN-1:0] mem_data_in,
    input wire [`XLEN-1:0] alu_result_in,
    input wire RegWrite_in, MemToReg_in,
    input wire [4:0] rd_addr_in,
    output reg [`XLEN-1:0] mem_data_out,
    output reg [`XLEN-1:0] alu_result_out,
    output reg RegWrite_out, MemToReg_out,
    output reg [4:0] rd_addr_out
);

    always @(posedge clk or posedge reset) begin
        if (reset || flush) begin
            mem_data_out <= 32'b0;
            alu_result_out <= 32'b0;
            RegWrite_out <= 1'b0;
            MemToReg_out <= 1'b0;
            rd_addr_out <= 5'b0;
        end else if (!stall) begin
            mem_data_out <= mem_data_in;
            alu_result_out <= alu_result_in;
            RegWrite_out <= RegWrite_in;
            MemToReg_out <= MemToReg_in;
            rd_addr_out <= rd_addr_in;
        end
    end

endmodule