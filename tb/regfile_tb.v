`timescale 1ps/1ps
`default_nettype none
`include "rtl/isa.vh"

module regfile_tb;
    localparam XLEN = 32;

    reg clk;
    reg reset;
    reg [4:0] rs1_addr;
    reg [4:0] rs2_addr;
    reg [4:0] rd;
    reg [XLEN-1:0] write_data;
    reg wr_en;
    wire [XLEN-1:0] rs1_data;
    wire [XLEN-1:0] rs2_data;

    regfile regfile_dut (
        .clk(clk),
        .reset(reset),
        .rs1_addr(rs1_addr),
        .rs2_addr(rs2_addr),
        .rd(rd),
        .write_data(write_data),
        .wr_en(wr_en),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("regfile.vcd");
        $dumpvars(0, regfile_tb);
    end

    task test_write(input [4:0] addr, input [31:0] data);
        @(posedge clk);
        rd = addr; write_data = data; wr_en = 1;
        @(posedge clk); wr_en = 0;
    endtask

    task test_read(input [4:0] addr, input [31:0] expected);
        @(posedge clk);
        rs1_addr = addr;
        @(posedge clk);
        if (rs1_data !== expected) 
            $error("FAIL: Reg %d: expected %h, got %h", addr, expected, rs1_data);
        else 
            $display("PASS: Reg %d: %h", addr, rs1_data);
    endtask
    
    initial begin
        reset = 1; wr_en = 0; rs1_addr = 0; rs2_addr = 0;
        #10; reset = 0;

        // reset
        test_write(5'd10, 32'h00000000);

        test_write(5'd1, 32'h00000001);
        test_write(5'd2, 32'h00000010);
        test_write(5'd3, 32'h00000100);

        // read
        test_read(5'd1, 32'h00000001);
        test_read(5'd2, 32'h00000010);
        test_read(5'd3, 32'h00000100);

        #100;
        $display("Complte");
        $finish;
    end

endmodule