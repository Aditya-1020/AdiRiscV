import riscv_pkg::*;

module tb_regfile;
    timeunit 1ns;
    timeprecision 1ps;

    logic clk;
    logic [4:0] rs1_addr, rs2_addr, rd;
    logic [XLEN-1:0] write_data;
    logic wr_en;
    logic [XLEN-1:0] rs1_data, rs2_data;

    localparam int LAST = NUM_REGS-1;
    int pass_count = 0;
    int fail_count = 0;
    // int test_num = 0;

    regfile dut (
        .clk(clk),
        .rs1_addr(rs1_addr),
        .rs2_addr(rs2_addr),
        .rd(rd),
        .write_data(write_data),
        .wr_en(wr_en),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data)
    );


    initial clk = 0;
    always #5 clk = ~clk; // 100 mhz

    task automatic write_reg(
        input logic [4:0] addr,
        input logic [XLEN-1:0] data
    );
        @(negedge clk);
        rd = addr;
        write_data = data;
        wr_en = 1'b1;
        @(posedge clk); // write
        #1; // delay... cause write wasnt finishing
        wr_en = 1'b0;
    endtask

    task automatic check_rs1(
        input logic [4:0] addr,
        input logic [XLEN-1:0] expected
    );
        rs1_addr = addr;
        #1;
        
        if (rs1_data !== expected) begin
            $error("RS1 READ FAIL: x%0d, expected %h,  got: %h", addr, expected, rs1_data);
            fail_count++;
        end else begin
            $display("RS1 READ PASS: x%0d, expeted: %h, got: %h", addr, expected, rs1_data);
            pass_count++;
        end
    
    endtask

    task automatic check_rs2(
        input logic [4:0] addr,
        input logic [XLEN-1:0] expected
    );

        rs2_addr = addr;
        #1;
    
        if (rs2_data !== expected) begin
            $error("RS2 READ FAIL: x%0d, expected %h,  got: %h", addr, expected, rs2_data);
            fail_count++;
        end else begin
            $display("RS2 READ PASS: x%0d, expeted: %h, got: %h", addr, expected, rs2_data);
            pass_count++;
        end

    endtask


    task automatic check_both_ports(
        input logic [4:0] addr1,
        input logic [4:0] addr2,
        input logic [XLEN-1:0] expected1,
        input logic [XLEN-1:0] expected2
    );
        rs1_addr = addr1;
        rs2_addr = addr2;
        #2;

        if (rs1_data !== expected1) begin
            $error("RS1 READ FAIL: x%0d, expected %h,  got: %h", addr1, expected1, rs1_data);
            fail_count++;
        end else begin
            $display("RS1 READ PASS: x%0d, expeted: %h, got: %h", addr1, expected1, rs1_data);
            pass_count++;
        end
        
        if (rs2_data !== expected2) begin
            $error("RS2 READ FAIL: x%0d, expected %h,  got: %h", addr2, expected2, rs2_data);
            fail_count++;
        end else begin
            $display("RS2 READ PASS: x%0d, expeted: %h, got: %h", addr2, expected2, rs2_data);
            pass_count++;
        end
        
    endtask


    task automatic check_x0;
        check_rs1(5'd0, '0);
        check_rs2(5'd0, '0);
    endtask
    

    initial begin
        // intialize registers
        for (int i = 0; i < NUM_REGS; i++) begin
            dut.registers[i] = '0;
        end

        #1;

        $dumpfile("regfile.vcd");
        $dumpvars(0, tb_regfile);

        wr_en = 0;
        rs1_addr = 0;
        rs2_addr = 0;
        rd = 0;
        write_data = 0;

        repeat(2) @(posedge clk);

        $display("Reg ttests");

        // x0
        $display("\nTest 1: x0 immutability");
        write_reg(5'd0, 32'h12345678);
        check_x0();
        
        // write/read
        $display("\nTest 2: write/read");
        write_reg(5'd5, 32'h12345678);
        $display("DEBUG: registers[5] = %h", dut.registers[5]);
        check_rs1(5'd5, 32'h12345678);
        
        // hishest index
        $display("\nTest 3: highest Reg index (x%0d)", LAST);
        write_reg(LAST, 32'hA5A5A5A5);
        check_rs1(LAST, 32'hA5A5A5A5);    
    
        // dual port simulatneous read
        $display("\nTest 4; dual port read simultaneous");
        write_reg(5'd1, 32'h11111111);
        write_reg(5'd31, 32'hFFFFFFFF);

        // write disabled (no data should chanege)
        $display("\nTest5: write disabled");
        write_reg(5'd8, 32'hAAAAAAAA);
        @(negedge clk);
        wr_en = 0;
        rd = 5'd8;
        write_data = 32'hBBBBBBBB;
        @(posedge clk);
        check_rs1(5'd8, 32'hAAAAAAAA);

        // same cycle dual read
        $display("\nTest6: same cycle dual read");
        write_reg(5'd2, 32'h22222222);
        write_reg(5'd3, 32'h33333333);
        check_both_ports(5'd2, 5'd3, 32'h22222222, 32'h33333333);

        // write through/forwarding (read while writing to same reg)
        $display("\nTest 7: write through/forwarding");
        write_reg(5'd10, 32'h12345678);
        @(negedge clk);
        rd = 5'd10;
        write_data = 32'h11111111;
        wr_en = 1'b1;
        rs1_addr = 5'd10;
        rs2_addr = 5'd10;
        #2;
        
        if (rs1_data !== 32'h11111111) begin
            $error("RS! Forwarding failed: x10, expected = %h, got = %h", 32'h11111111, rs1_data);
            fail_count++;
        end else begin
            $display("RS1 Forwarding passed: x10, expected = %h, got = %h", 32'h11111111, rs1_data);
            pass_count++;
        end

        if (rs2_data !== 32'h11111111) begin
            $error("RS2 Forwarding failed: x10, expected = %h, got = %h", 32'h11111111, rs2_data);
            fail_count++;
        end else begin
            $display("RS2 Forwarding passed: x10, expected = %h, got = %h", 32'h11111111, rs2_data);
            pass_count++;
        end
        @(posedge clk);
        wr_en = 1'b0;


        // write pattern to all regs except x0
        $display("\nTest 8: write pattern to all registers");
        for (int i = 1; i < NUM_REGS; i++) begin
            write_reg(i[4:0], 1 << (i % XLEN));
            check_rs1(i[4:0], 1 << (i % XLEN));
        end

        // verify x0 after all tests
        $display("\nTest 9: verify x0 after operations");
        check_x0();

        // summary;
        repeat(2) @(posedge clk);
        #10;
        $display("\nTest summary");
        $display("passd: %0d", pass_count);
        $display("failed: %0d", fail_count);
        $display("total: %0d", pass_count + fail_count);
        if (fail_count == 0)
            $display("all test passed");
        else
            $display("some test failed");

        $finish;
    end

    initial begin
        #10000;
        $error("TIMEOUT: Tb did not compile in time");
        $finish;
    end

endmodule