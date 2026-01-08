import riscv_pkg::*;

module tb_branch_unit;

    timeunit 1ns;
    timeprecision 1ps;

    logic [XLEN-1:0] rs1_data, rs2_data;
    logic [XLEN-1:0] pc, imm;
    funct3_branch_e funct3;
    opcode_e opcode;
    logic branch_taken;
    logic [XLEN-1:0] branch_target;
    logic is_jump;

    int pass_count = 0;
    int fail_count = 0;

    branch_unit dut (
        .rs1_data(rs1_data),
        .rs2_data(rs2_data),
        .pc(pc),
        .imm(imm),
        .funct3(funct3),
        .opcode(opcode),
        .branch_taken(branch_taken),
        .branch_target(branch_target),
        .is_jump(is_jump)
    );


    task check_result(
        input logic expected_taken,
        input logic [XLEN-1:0] expected_target,
        input logic expected_is_jump
    );
        #1;

        if (branch_taken !== expected_taken || 
            branch_target !== expected_target || 
            is_jump !== expected_is_jump) begin

                $display("FAILED: expected: taken=%b, target=0x%h, is_jump=%b", expected_taken, expected_target, expected_is_jump);
                fail_count++;
        end else begin
                $display("PASSED: expected: taken=%b, target=0x%h, is_jump=%b", expected_taken, expected_target, expected_is_jump);
                pass_count++;
            end
    endtask

    initial begin
        $dumpfile("branch_unit.vcd");
        $dumpvars(0, tb_branch_unit);

        $display("branch unit Tests");

        opcode = OP_BRANCH;
        funct3 = F3_BEQ;
        rs1_data = 32'h0000000A;
        rs2_data = 32'h0000000A;
        pc = 32'h00001000;
        imm = 32'h00000100;
        check_result(1'b1, 32')


    end


endmodule