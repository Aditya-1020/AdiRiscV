`timescale 1ps/1ps
`default_nettype none
`include "rtl/isa.vh"

module top (
    input wire clk,
    input wire reset,
    output wire [`XLEN-1:0] pc_if_debug, pc_id_debug,
    output wire [`XLEN-1:0] instruction_if_debug, instruction_id_debug,
    output wire [31:0] cycle_count, instruction_count, stall_count,
    output wire [31:0] branch_count, branch_mispredicts,
    output wire branch_mispredict_signal,
    output wire icache_stall_signal
);

    wire branch, MemRead, MemToReg, MemWrite, ALUSrc, RegWrite;
    wire [3:0] ALU_op;
    wire is_branch, is_jump, is_jal, is_jalr, is_load, is_store;
    
    wire [`XLEN-1:0] instruction_id;
    assign instruction_id = instruction_id_debug;

    control_unit control_unit_inst (
        .instruction(instruction_id),
        .branch(branch),
        .MemRead(MemRead),
        .MemToReg(MemToReg),
        .ALU_op(ALU_op),
        .MemWrite(MemWrite),
        .ALUSrc(ALUSrc),
        .RegWrite(RegWrite),
        .is_branch(is_branch),
        .is_jump(is_jump),
        .is_jal(is_jal),
        .is_jalr(is_jalr),
        .is_load(is_load),
        .is_store(is_store)
    );

    datapath dp (
        .clk(clk),
        .reset(reset),
        .branch_id(branch),
        .MemRead_id(MemRead),
        .MemToReg_id(MemToReg),
        .ALU_op_id(ALU_op),
        .MemWrite_id(MemWrite),
        .ALUSrc_id(ALUSrc),
        .RegWrite_id(RegWrite),
        .is_jal_id(is_jal),
        .is_jalr_id(is_jalr),
        .is_branch_id(is_branch),
        .is_jump_id(is_jump),
        .pc_if_debug(pc_if_debug),
        .instruction_if_debug(instruction_if_debug),
        .pc_id_debug(pc_id_debug),
        .instruction_id_debug(instruction_id_debug),
        .branch_mispredict(branch_mispredict_signal),
        .icache_stall(icache_stall_signal)
    );

    performance_counters performance_counters_inst (
        .clk(clk),
        .reset(reset),
        .instruction_valid(instruction_id_debug != `NOP_INSTRUCTION),
        .is_branch(is_branch),
        .branch_mispredict(branch_mispredict_signal),
        .stall(icache_stall_signal),
        .cycle_count(cycle_count),
        .instruction_count(instruction_count),
        .stall_count(stall_count),
        .branch_count(branch_count),
        .branch_mispredicts(branch_mispredicts)
    );

endmodule

module performance_counters (
    input wire clk,
    input wire reset,
    input wire instruction_valid,
    input wire is_branch,
    input wire branch_mispredict,
    input wire stall,
    output reg [31:0] cycle_count,
    output reg [31:0] instruction_count,
    output reg [31:0] stall_count,
    output reg [31:0] branch_count,
    output reg [31:0] branch_mispredicts
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            cycle_count <= 32'b0;
            instruction_count <= 32'b0;
            stall_count <= 32'b0;
            branch_count <= 32'b0;
            branch_mispredicts <= 32'b0;
        end else begin
            cycle_count <= cycle_count + 1;

            if (instruction_valid && !stall)
                instruction_count <= instruction_count + 1;

            if (stall)
                stall_count <= stall_count + 1;
            
            if (is_branch && instruction_valid && !stall) // Count branch in ID
                branch_count <= branch_count + 1;
            
            if (branch_mispredict)
                branch_mispredicts <= branch_mispredicts + 1;
        end
    end

endmodule
