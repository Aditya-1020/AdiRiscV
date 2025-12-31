`timescale 1ps/1ps
`default_nettype none
`include "rtl/isa.vh"

module pc_plus4_tb;
    localparam XLEN = 32;

    reg [XLEN-1:0] pc_in;
    wire [XLEN-1:0] pc_plus4;

    pc_plus4 pc_plus4_dut (
        .pc_in(pc_in),
        .pc_plus4(pc_plus4)
    );

    initial begin
        $dumpfile("pc_plus4_tb.vcd");
        $dumpvars(0, pc_plus4_tb);
    end

    initial begin
        $display("Testing pc_plus4...");

        pc_in = '0;
        #10;
        if (pc_plus4 !== 32'h0000_0004) 
            $fatal(2, "FAIL: 0x0 + 4 = %h", pc_plus4);
        else 
            $display("PASS: 0x0 + 4 = %h", pc_plus4);

        // midrange  
        pc_in = 32'h0000_0100;
        #10;
        if (pc_plus4 !== 32'h0000_0104) 
            $fatal(2, "FAIL: 0x100 + 4 = %h", pc_plus4);
        else 
            $display("PASS: 0x100 + 4 = %h", pc_plus4);

        // near overflow
        pc_in = 32'hFFFF_FFFC;
        #10;
        if (pc_plus4 !== 32'h0)  // FFFC + 4 = 0 (wraparound)
            $fatal(2, "FAIL: 0xFFFC + 4 = %h", pc_plus4);
        else 
            $display("PASS: 0xFFFC + 4 = %h", pc_plus4);

        // ioverflow wrap
        pc_in = 32'hFFFF_FFFD;
        #10;
        if (pc_plus4 !== 32'h1) 
            $fatal(2, "FAIL: 0xFFFD + 4 = %h", pc_plus4);
        else 
            $display("PASS: 0xFFFD + 4 = %h", pc_plus4);

        $finish;
    end
endmodule
