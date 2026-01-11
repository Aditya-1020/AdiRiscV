import riscv_pkg::*;

module tb_imem;
    
    timeunit 1ns;
    timeprecision 1ps;

    logic [WORD_ADDR_WIDTH-1:0] address;
    logic [XLEN-1:0] instruction;

    int pass_count = 0;
    int fail_count = 0;
    
    imem dut (
        .address(address),
        .instruction(instruction)
    );

    task automatic check_instruction(
        input logic [WORD_ADDR_WIDTH-1:0] addr,
        input logic [XLEN-1:0] expected
    );
        address = addr;
        #1;

        if (instruction !== expected) begin
            $display("FAIL: address=%0d (0x%h), expected=0x%08h, got=0x%08h", addr, addr, expected, instruction);
            fail_count++;
        end else begin
            $display("PASS: address=%0d (0x%h), expected=0x%08h, got=0x%08h", addr, addr, expected, instruction);
            pass_count++;
        end
    endtask


    // intialize memory
    task automatic init_mem_pattern(input int pattern);
        case (pattern)
            0: begin // NOP
                for (int i = 0; i < IMEM_SIZE; i++)
                    dut.imem[i] = NOP_INSTR;
            end
            1: begin // address as data
                for (int i = 0; i < IMEM_SIZE; i++)
                    dut.imem[i] = i;
            end
            2: begin // test mini program
                dut.imem[0] = 32'h00000013; // ADDI x0, x0, 0 (NOP)
                dut.imem[1] = 32'h00100093; // ADDI x1, x0, 1
                dut.imem[2] = 32'h00200113; // ADDI x2, x0, 2
                dut.imem[3] = 32'h002081B3; // ADD x3 x1, x2
                for (int i = 4; i < IMEM_SIZE; i++) begin
                    dut.imem[i] = NOP_INSTR;
                end
            end
        endcase
    endtask

    // test read
    task automatic test_seq_read();
        $display("\nseqeuntial read");

        for (int i = 0; i < 10; i++) begin
            check_instruction(i, i);
        end
    endtask

    // out of bounds
    task automatic test_out_of_bounds();
        $display("\nout of bounds access");

        check_instruction(IMEM_SIZE-1, NOP_INSTR); // last valid returns 1023
        check_instruction(IMEM_SIZE, NOP_INSTR); // first invalid
        check_instruction(IMEM_SIZE+100, NOP_INSTR); // wrap around 1124 andbcomes 100

    endtask

    task automatic test_address_zero();
        $display("\naddress zero");
        check_instruction(0, dut.imem[0]);
    endtask

    task automatic test_rand_addr();
        int rand_addr;
        
        $display("\nrandom address");        
        
        for (int i = 0; i < 20; i++) begin
            rand_addr = $urandom_range(0, IMEM_SIZE-1);  // Generate new address
            check_instruction(rand_addr, dut.imem[rand_addr]);
        end
    endtask

    task automatic test_cont_read();
        $display("\ncontinous reads");
        for (int i = 0; i < 5; i++) begin
            address = i;
            #1;
            check_instruction(i, dut.imem[i]);
        end
    endtask

    initial begin
        $dumpfile("tb_imem.vcd");
        $dumpvars(0, tb_imem);

        $display("\n IMEM Tests");
        $display("size=%0d words (%0d bytes)", IMEM_SIZE, IMEM_SIZE*4);
        $display("Address width=%0d bits", WORD_ADDR_WIDTH);

        init_mem_pattern(0); // FILL NOP
        #10;
        test_out_of_bounds();

        #1;

        // pattern 1
        init_mem_pattern(1);
        $display("\n pattern 1");
        $display("First 8 instructions");
        for (int i = 0; i < 8; i++) begin
            $display("[%0d] = 0x%08h", i, dut.imem[i]);
        end
        // tests on 1
        #10;
        test_address_zero();
        test_seq_read();
        // test_out_of_bounds();
        test_rand_addr();
        test_cont_read();

        // patters 2
        init_mem_pattern(2);
        $display("\nTesting pattern 2");
        $display("\nFirst 4 instructions");
        for (int i = 0; i < 4; i++) begin
            $display("[%0d] = 0x%08h", i, dut.imem[i]);
        end
        // verify pattern 2
        check_instruction(0, 32'h00000013);
        check_instruction(1, 32'h00100093);
        check_instruction(2, 32'h00200113);
        check_instruction(3, 32'h002081B3);

        
        $display("\nTest summary");
        $display("passed: %0d", pass_count);
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