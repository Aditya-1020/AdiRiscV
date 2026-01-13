import riscv_pkg::*;

module tb_dmem;

    timeunit 1ns;
    timeprecision 1ps;

    logic clk;
    // logic reset;
    logic [XLEN-1:0] addr, wdata;
    logic rd_en, wr_en;
    mem_op_e mem_op;
    logic [XLEN-1:0] rdata;

    int pass_count = 0;
    int fail_count = 0;

    dmem dut (
        .clk(clk),
        // .reset(reset),
        .addr(addr),
        .wdata(wdata),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .mem_op(mem_op),
        .rdata(rdata)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    // initialization
    task automatic init_dmem_pattern(input int pattern);
        case (pattern)
            0: begin // zeros
                for (int i = 0; i < DMEM_SIZE; i++)
                    dut.mem[i] = 8'h00;
            end
            1: begin // all ones
                for (int i = 0; i < DMEM_SIZE; i++)
                    dut.mem[i] = 8'hFF;
            end
            2: begin // address as data
                for (int i = 0; i < DMEM_SIZE; i++)
                    dut.mem[i] = i[7:0];
            end
        endcase
    endtask

    task automatic check_result(
        input string name,
        input logic [XLEN-1:0] expected,
        input logic [XLEN-1:0] result
    );
        if (expected == result) begin
            $display("PASS: %s, Expected: 0x%08h, Got: 0x%08h \t time:%0t", name, expected, result, $time);
            pass_count++;
        end else begin
            $display("FAIL: %s, Expected: 0x%08h, Got: 0x%08h \t time:%0t", name, expected, result, $time);
            fail_count++;
        end
    endtask

    task automatic write_mem(
        input logic [XLEN-1:0] address,
        input logic [XLEN-1:0] data,
        input mem_op_e mem_operation
    );
        @(posedge clk);
        #1;
        addr = address;
        wdata = data;
        wr_en = 1'b1;
        rd_en = 1'b0;
        mem_op = mem_operation;
        
        @(posedge clk); // write
        #1;
        wr_en = 1'b0;
    endtask

    task automatic read_mem(
        input logic [XLEN-1:0] address,
        input mem_op_e mem_operation,
        output logic [XLEN-1:0] data
    );
        @(posedge clk); // sync to clk edge
        #1;
        addr = address;
        rd_en = 1'b1;
        wr_en = 1'b0;
        mem_op = mem_operation;
        
        #1; // settle data
        data = rdata;

        @(posedge clk); // wait for next clock
        #1; // tiny delay timing issue
        rd_en = 1'b0;
    endtask

    // for personal refference
    // write_mem(address, data, mem_operation);
    // read_mem(address, mem_operation, data);
    // check_result(name, expected, result);

    task automatic word_operations();
        logic [XLEN-1:0] read_data;

        $display("\nword operations");

        // test 1
        write_mem(32'h00000000, 32'h12345678, MEM_WORD);
        read_mem(32'h00000000, MEM_WORD, read_data);
        check_result("word wr/rd at 0x00", 32'h12345678, read_data);

        // test 2
        write_mem(32'h00000004, 32'h87654321, MEM_WORD);
        
        #10;

        read_mem(32'h00000004, MEM_WORD, read_data);
        check_result("word wr/rd at 0x04", 32'h87654321, read_data);
        
        #10;

        // test verify write
        read_mem(32'h00000000, MEM_WORD, read_data);
        check_result("verify write after t2", 32'h12345678, read_data);
    endtask
    
    task automatic byte_operations();
        logic [XLEN-1:0] read_data;
        logic [7:0] expected_byte;
        logic [31:0] expected_word;

        $display("\nByte operations");
        init_dmem_pattern(2); // address as data

        // signed byte load at different offsets
        for (int offset = 0; offset < 4; offset++) begin
            
            read_mem(32'h00000000+offset,MEM_BYTE, read_data);

            expected_byte = offset[7:0];
            expected_word = {{24{expected_byte[7]}}, expected_byte};
            check_result($sformatf("LB at offest %0d", offset), expected_word, read_data);
        end

        //unsigned byte load
        dut.mem[0] = 8'h80; // neg if signed
        read_mem(32'h00000000, MEM_BYTE_U, read_data);
        check_result("LBU sign", 32'h00000080, read_data);

        // byte store at offsets
        for (int offset = 0; offset < 4; offset++) begin
            
            write_mem(32'h00000010 + offset, 32'h000000A5 ,MEM_BYTE);
            read_mem(32'h00000010 + offset, MEM_BYTE_U, read_data);
            check_result($sformatf("SB at offest %0d", offset), 32'h000000A5, read_data);
        end

    endtask

    task automatic half_word_operations();
        logic [XLEN-1:0] read_data;

        $display("\nHalf-word operations");

        init_dmem_pattern(0); // clear
        
        // max pos halfwaord
        write_mem(32'h00000020, 32'h00007FFF, MEM_HALF);
        read_mem(32'h00000020, MEM_HALF, read_data);
        check_result("LH max pos", 32'h00007FFF, read_data);

        // min neg halfword
        write_mem(32'h00000022, 32'h00008000, MEM_HALF);
        read_mem(32'h00000022, MEM_HALF, read_data);
        check_result("LH min neg", 32'hFFFF8000, read_data);

        // unsigned halfword
        read_mem(32'h00000022, MEM_HALF_U, read_data);
        check_result("LHU min neg", 32'h00008000, read_data);
    endtask

    task automatic alignment_edge_cases();
        logic [XLEN-1:0] read_data;

        $display("\nalignment edge csaes");

        // halfword at offset 2
        write_mem(32'h00000002, 32'h0000ABCD, MEM_HALF);
        read_mem(32'h00000002, MEM_HALF_U, read_data);
        check_result("halfword at offset 2", 32'h0000ABCD, read_data);

        // indiv bytes of halfword written
        read_mem(32'h00000002, MEM_BYTE_U, read_data);
        check_result("Byt 0 of halfword", 32'h000000CD, read_data);
        
        read_mem(32'h00000003, MEM_BYTE_U, read_data);
        check_result("Byte 1 of halfword", 32'h000000AB, read_data);
    endtask


    initial begin
        $dumpfile("dmem.vcd");
        $dumpvars(0, tb_dmem);

        $display("DMEM TESST");

        addr = '0;
        wdata = '0;
        wr_en = 0;
        rd_en = 0;
        mem_op = MEM_WORD;

        repeat(2) @(posedge clk);
        
        // Tests
        init_dmem_pattern(0);
        word_operations();

        init_dmem_pattern(2);
        byte_operations();

        init_dmem_pattern(0);
        half_word_operations();

        init_dmem_pattern(0);
        alignment_edge_cases();


        repeat(2) @(posedge clk);
        $display("\n\nTest summary");
        $display("passed: %0d", pass_count);
        $display("failed: %0d", fail_count);
        $display("total: %0d", pass_count + fail_count);
        if (fail_count == 0)
            $display("all test passed");
        else
            $display("some test or tests failed");

        $finish;
    end

    initial begin
        #10000;
        $error("TIMEOUT: Tb did not compile in time");
        $finish;
    end

endmodule