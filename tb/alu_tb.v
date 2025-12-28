`timescale 1ps/1ps
`default_nettype none
`include "rtl/isa.v"

module alu_tb;
    localparam XLEN = 32;
    
    // Testbench signals
    reg [XLEN-1:0] a, b;
    reg [3:0] ALUControl;
    wire zero;
    wire [XLEN-1:0] result;

    alu alu_dut (
        .a(a),
        .b(b),
        .ALUControl(ALUControl),
        .zero(zero),
        .result(result)
    );

    wire signed [XLEN-1:0] tb_signed_a = $signed(a);
    wire signed [XLEN-1:0] tb_signed_b = $signed(b);

    initial begin
        $dumpfile("alu.vcd");
        $dumpvars(0, alu_tb);

        test_add();
        test_sub();
        test_sll();
        test_slt();
        test_sltu();
        test_xor();
        test_srl();
        test_sra();
        test_or();
        test_and();
        test_pass();

        #100 $finish;
    end

    task test_add;
        $display("Testing add");
        begin
        a = 32'd5; b = 32'd3; ALUControl = `ALU_ADD; #10; check_result(8, 1'b0);
        end
        begin
        a = -32'd5; b = 32'd3; ALUControl = `ALU_ADD; #10; check_result(-2,1'b0);
        end
    endtask

    task test_sub;
        $display("Testing sub");
        begin
        a = 32'd6; b = 32'd3; ALUControl = `ALU_SUB; #10; check_result(3,1'b0);
        end
        begin
        a = 32'd0; b = 32'd5; ALUControl = `ALU_SUB; #10; check_result(-5,1'b0);
        end
    endtask

    task test_sll;
        $display("Testing sll");
        begin
        a = 32'd6; b = 32'd2; ALUControl = `ALU_SLL; #10; check_result(24,1'b0);
        end
        begin
        a = 32'd1; b = 32'd3; ALUControl = `ALU_SLL; #10; check_result(8, 1'b0);
        end
        begin
        a = 32'd17; b = 32'd32; ALUControl = `ALU_SLL; #10; check_result(17, 1'b0);
        end
    endtask

    task test_slt;
        $display("Testing slt");
        begin
        a = 32'd5; b = 32'd7; ALUControl = `ALU_SLT; #10; check_result(1,1'b0);
        end
        begin
        a = -32'd1; b = 32'd1; ALUControl = `ALU_SLT; #10; check_result(1,1'b0);
        end
    endtask

    task test_sltu;
        $display("Testing sltu");
        begin
        a = 32'hFFFFFFFF; b = 32'd1; ALUControl = `ALU_SLTU; #10; check_result(1, 1'b0);
        end
    endtask

    task test_xor;
        $display("Testing xor");
        begin
        a = 32'd1; b = 32'd1; ALUControl = `ALU_XOR; #10; check_result(0,1'b1);
        end
        begin
        a = 32'h12345678; b = 32'h0000FFFF; ALUControl = `ALU_XOR; #10; check_result(32'h1234A987, 1'b0);
        end
        begin
        a = 32'hFFFFFFFF; b = 32'hFFFFFFFF; ALUControl = `ALU_XOR; #10; check_result(0,1'b1);
        end
    endtask

    task test_srl;
        $display("Testing srl");
        begin
        a = 32'd4; b = 32'd2; ALUControl = `ALU_SRL; #10; check_result(1,1'b0);
        end
        begin
        a = 32'd1; b = 32'd3; ALUControl = `ALU_SRL; #10; check_result(0,1'b1);
        end
        begin
        a = 32'hF0; b = 32'd4; ALUControl = `ALU_SRL; #10; check_result(32'hF, 1'b0);
        end
    endtask

    task test_sra;
        $display("Testing sra");
        begin
        a = 32'hFFFFFFF8; b = 32'd2; ALUControl = `ALU_SRA; #10; check_result(32'hFFFFFFFE, 1'b0);
        end
        begin
        a = 32'd24; b = 32'd2; ALUControl = `ALU_SRA; #10; check_result(6,1'b0);
        end
    endtask

    task test_or;
        $display("Testing or");
        begin
        a = 32'd0; b = 32'd0; ALUControl = `ALU_OR; #10; check_result(0,1'b1);
        end
        begin
        a = 32'd1; b = 32'd0; ALUControl = `ALU_OR; #10; check_result(1,1'b0);
        end
        begin
        a = 32'hF0; b = 32'h0F; ALUControl = `ALU_OR; #10; check_result(32'hFF, 1'b0);
        end
    endtask

    task test_and;
        $display("Testing and");
        begin
        a = 32'd0; b = 32'd0; ALUControl = `ALU_AND; #10; check_result(0,1'b1);
        end
        begin
        a = 32'd1; b = 32'd0; ALUControl = `ALU_AND; #10; check_result(0,1'b1);
        end
        begin
        a = 32'hF0; b = 32'h0F; ALUControl = `ALU_AND; #10; check_result(0,1'b1);
        end
    endtask

    task test_pass;
        $display("Testing pass");
        begin
        a = 32'h12345678; ALUControl = `ALU_PASS_A; #10; check_result(32'h12345678, 1'b0);
        end
        begin
        b = 32'h87654321; ALUControl = `ALU_PASS_B; #10; check_result(32'h87654321,1'b0);
        end
    endtask

    task check_result;
        input [31:0] expected_result;
        input expected_zero;
        begin
            if (result != expected_result) begin
                $error("FAIL: expected %h, got %h", expected_result, result);
            end else begin
                $display("PASS: result = %h", result);
            end
            if (zero != expected_zero) begin
                $error("FAIL: expected zero=%b, got %b", expected_zero, zero);
            end else begin
                $display("PASS: zero = %b", zero);
            end
        end
    endtask

    always @(posedge alu_dut.result or posedge alu_dut.zero) begin
        $display("Time %0t: result=0x%8h (%0d), zero=%b, a=0x%8h, b=0x%8h, control=%0d",
                 $time, result, $signed(result), zero, a, b, ALUControl);
    end
endmodule