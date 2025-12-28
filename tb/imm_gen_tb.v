`timescale 1ps/1ps
`default_nettype none
`include "rtl/isa.v"

module imm_gen_tb;
    parameter XLEN = `XLEN ;

    reg [XLEN-1:0] instruction;
    wire [XLEN-1:0] immediate;
    // reg [6:0] opcode;
    // reg [XLEN-1:0] i_imm, s_imm, b_imm, u_imm, j_imm;

    imm_gen imm_gen_dut (
        .instruction(instruction),
        .immediate(immediate)
    );

    task test_imm(input [31:0] instr, input [31:0] expected_imm);
        instruction = instr;
        #10;
        $display("Instr=%h opcode=%h imm=%h (exp=%h)", instr, instr[6:0], immediate, expected_imm);
        
        if (immediate !== expected_imm)
            $error("FAIL");
        else 
            $display("PASS");
    endtask

    initial begin
        $dumpfile("imm_gen.vcd");
        $dumpvars(0, imm_gen_tb);

      $display("Testing I-type");
      test_imm(32'h07B00593, 32'h0000007B);
      test_imm(32'hFF000093, 32'hFFFFFFF0);
       
       $display("Testing S-type");
       test_imm(32'h02412223, 32'h00000024);
       
       $display("Testing B-type");
       test_imm(32'h00000063, 32'h00000000);
       
       $display("Testing U-type");
       test_imm(32'h12345037, 32'h12345000);
       
       $display("Testing J-type");
       test_imm(32'h002003ef, 32'h00000002);
       
       $display("Testing default");
       test_imm(32'h00000000, 32'h00000000);

        $display("ALL Tests completed");
        $finish;
    end


endmodule