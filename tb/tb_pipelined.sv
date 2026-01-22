import riscv_pkg::*;

module tb_pipelined;

    timeunit 1ns;
    timeprecision 1ps;

    logic clk;
    logic reset;

    initial clk = 0;
    always #5 clk = ~clk; // 100mhz

    riscv_pipelined_core dut (
        .clk(clk),
        .reset(reset)
    );

    task automatic load_hex(string filename);
        $readmemh(filename, dut.if_stage_inst.imem_inst.imem);
        $display("Loading program from hex %s", filename);
    endtask

    task automatic verify_loaded_program();
        $display("Verifying loaded program");
        $display("First 20 instructions:");
        for (int i = 0; i < 20; i++) begin
            if (dut.if_stage_inst.imem_inst.imem[i] != NOP_INSTR) begin
                $display("  imem[%0d] = 0x%08h", i, dut.if_stage_inst.imem_inst.imem[i]);
            end
        end
    endtask

    task automatic display_registers();
        $display("\nFinal Register State (time: %0t)", $time);
        $display("PC = 0x%08h", dut.if_stage_inst.pc_inst.pc);
        $display("\nNon-zero Registers:");
        for (int i = 0; i < 32; i++) begin
            if (dut.id_stage_inst.regfile_inst.registers[i] != 0) begin
                $display("  x%-2d = 0x%08h (%0d)", i, dut.id_stage_inst.regfile_inst.registers[i], 
                        $signed(dut.id_stage_inst.regfile_inst.registers[i]));
            end
        end
    endtask

    task automatic check_register(int reg_num, logic [XLEN-1:0] expected, string test_name);
        logic [XLEN-1:0] actual;
        actual = dut.id_stage_inst.regfile_inst.registers[reg_num];

        if (actual == expected) begin
            $display("PASS: x%0d = 0x%08h (%s)", reg_num, actual, test_name);
        end else begin
            $error("FAIL: x%0d expected 0x%08h, got 0x%08h (%s)", reg_num, expected, actual, test_name);
        end
    endtask

    initial begin
        $dumpfile("pipelined.vcd");
        $dumpvars(0, tb_pipelined);


        $display("   _____       .___.____________.__            ____   ____");
        $display("  /  _  \\    __| _/|__\\______   \\__| ______ ___\\   \\ /   /");
        $display(" /  /_\\  \\  / __ | |  ||       _/  |/  ___// ___\\   Y   / ");
        $display("/    |    \\/ /_/ | |  ||    |   \\  |\\___ \\\\  ___\\      /  ");
        $display("\\____|__  /\\____ | |__||____|_  /__/____  >\\___  >\\___/   ");
        $display("        \\/      \\/            \\/        \\/     \\/       ");
        $display("");
        $display("=============================================================");
        $display("             Testbench Starting...");
        $display("=============================================================");

        reset = 1;

        load_hex("programs/TEST.hex");
        // verify_loaded_program();
        
        // reset
        repeat(3) @(posedge clk);
        reset = 0;

        repeat(200) @(posedge clk);

        $display("\nAdiRISCV TEST\n");

        $display("Completion Markers:");
        check_register(15, 32'd3,        "Loop counter");
        check_register(18, 32'h000000AA, "Test marker 1");
        check_register(19, 32'h000000BB, "Test marker 2");
        check_register(20, 32'h000000CC, "Test marker 3");
        
        $display("\nForwarding Chain Tests:");
        check_register(5,  32'd1, "Forwarding start");
        check_register(6,  32'd2, "EX-EX forwarding");
        check_register(7,  32'd4, "EX-EX forwarding");
        check_register(8,  32'd8, "EX-EX forwarding");
        
        $display("\nBranch Tests:");
        check_register(23, 32'd1, "BEQ: branch not taken (42!=4), x23=1");
        check_register(26, 32'd2, "BEQ: branch not taken (5!=10), x26=2");
        check_register(27, 32'd0, "BNE: branch taken (5!=10), skips x27=3");
        check_register(28, 32'd0, "BLT: branch taken (5<10), skips x28=4");
        check_register(29, 32'd0, "BGE: branch taken (10>=5), skips x29=5");
        
        $display("\nUnsigned Comparison Tests:");
        check_register(9,  32'hFFFFFFFF, "Unsigned value 0xFFFFFFFF");
        check_register(10, 32'd1, "Unsigned value 1");
        check_register(11, 32'd1, "SLTU result (1 < 0xFFFFFFFF)");
        check_register(12, 32'd0, "SLTU result (0xFFFFFFFF >= 1)");
        check_register(13, 32'd100, "BLTU: branch taken (1<0xFFFFFFFF), x13 stays 100");
        check_register(14, 32'd100, "BGEU: branch taken (0xFFFFFFFF>=1), x14 stays 100");
        
        $display("\nMemory and Sign Extension Tests:");
        check_register(1,  32'h000000FF, "LBU (zero extended)");
        check_register(31, 32'hFFFFFFFF, "LB (sign extended)");
        
        $display("\n\nTEST COMPLETE");
        $finish;
    end

    initial begin
        #100000;
        $error("TIMEOUT: Tb did not compile in time");
        $finish;
    end

endmodule