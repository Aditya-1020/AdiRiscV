`timescale 1ps/1ps
`default_nettype none
`include "rtl/isa.v"

module pc_tb;
    localparam XLEN = 32;

    reg clk;
    reg reset;
    reg pc_en;
    reg [XLEN-1:0] pc_next;
    wire [XLEN-1:0] pc;

    pc pc_dut (
        .clk(clk),
        .reset(reset),
        .pc_en(pc_en),
        .pc_next(pc_next),
        .pc(pc)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("pc_tb.vcd");
        $dumpvars(0, pc_tb);
    end

    task test_reset_pc; begin
        reset = 1;
        pc_en = 0;
        pc_next = '0;
        
        @(posedge clk);
        @(posedge clk);
        
        if (pc !== `RESET_PC) begin
            $display("FAIL: reset pc = %h, expected = %h", pc, `RESET_PC);
            $fatal;
        end else begin
            $display("PASS: reset");
        end
        reset = 0;
    end
    endtask

    task test_pc_advance(input [XLEN-1:0] next_pc);
    begin
        pc_next = next_pc;
        pc_en = 1;
        @(posedge clk);
        if (pc !== next_pc) begin
            $display("FAIL: pc advance = %h, expected = %h", pc, next_pc);
            $fatal;
        end else begin
            $display("PASS: pc advance to %h", next_pc);
        end
    end
    endtask

    task test_pc_hold;
    begin
        reg [XLEN-1:0] old_pc;
        begin
           old_pc = pc;
           #1;
           pc_next = '0;
           pc_en = 0;
           @(posedge clk);

           if (pc !== old_pc) begin
                $display("FAIL: pc changed = %h | %h", pc, old_pc);
                $fatal;
           end else begin
                $display("PASS: pc hold");
           end
        end
    end
    endtask


    initial begin
        reset = 0;
        pc_en = 0;
        pc_next = 0;
        repeat (2) @(posedge clk);

        test_reset_pc();
        test_pc_advance(32'h0000_0004);
        test_pc_advance(32'h0000_0008);
        test_pc_hold();
        test_pc_advance(32'h0000_000C);

        $display("ALL TESTS PASSED");
        $finish;
    end
endmodule