`timescale 1ps/1ps
`default_nettype none
`include "rtl/isa.v"

module alu_control_tb;
    localparam XLEN = 32;

    reg [1:0] ALUOp;
    reg instr_30;
    reg [2:0] funct3;
    reg [3:0] ALUControl;
    reg [3:0] expected;

    alu_control alu_control_dut (
        .ALUOp(ALUOp),
        .instr_30(instr_30),
        .funct3(funct3),
        .ALUControl(ALUControl)
    );

    reg [10:0] mem [0:11]; // {ALUOp, instr_30, funct3, expected}

    integer i;
    initial begin
        $dumpfile("alu_control_tb.vcd");
        $dumpvars(0, alu_control_tb);

        $readmemh("test_vectors.mem", mem);

        for (i = 0; i<12; i++) begin
            {ALUOp, instr_30, funct3, expected} = mem[i];
            #5;

            if (ALUControl !== expected) begin
                $error("FAIL: %0d: %b %b %b -> %b (exp %b)", i, ALUOp, instr_30, funct3, ALUControl, expected);
            end else begin
                $display("PASS: %0d: %b %b %b -> %b", i, ALUOp, instr_30, funct3, ALUControl);
            end
        end
        $finish;
    end
endmodule