`timescale 1ps/1ps
`include "rtl/isa.vh"

module tb_top;
    reg clk;
    reg reset;
    wire [31:0] pc_if, pc_id;
    wire [31:0] instr_if, instr_id;
    wire [31:0] cycle_count, instruction_count, stall_count;
    wire [31:0] branch_count, branch_mispredicts;
    wire branch_mispredict, icache_stall;
    
    top dut (
        .clk(clk),
        .reset(reset),
        .pc_if_debug(pc_if),
        .pc_id_debug(pc_id),
        .instruction_if_debug(instr_if),
        .instruction_id_debug(instr_id),
        .cycle_count(cycle_count),
        .instruction_count(instruction_count),
        .stall_count(stall_count),
        .branch_count(branch_count),
        .branch_mispredicts(branch_mispredicts),
        .branch_mispredict_signal(branch_mispredict),
        .icache_stall_signal(icache_stall)
    );
    
    initial clk = 0;
    always #5000 clk = ~clk; // 100MHz
    
    initial begin
        $dumpfile("pipeline.vcd");
        $dumpvars(0, tb_top);

        reset = 1;
        #50000;
        reset = 0;

        #50000000; // 100MHz in 500 cycles

        $display("\nperfromance");
        $display("Total Cycles:        %d", cycle_count);
        $display("Instructions:        %d", instruction_count);
        $display("Stalls:              %d", stall_count);
        $display("Branches:            %d", branch_count);
        $display("Mispredictions:      %d", branch_mispredicts);
        $display("CPI:                 %.3f", cycle_count / (instruction_count * 1.0));
        $display("Branch Accuracy:     %.1f%%", (1.0 - (branch_mispredicts / (branch_count * 1.0))) * 100.0);
        $display("Stall Rate:          %.1f%%", (stall_count / (cycle_count * 1.0)) * 100.0);
        $finish;
    end

    initial begin
        #100000000; // 10us timeout
        $display("TIMEOUT - Simulation stopped");
        $finish;
    end
    
endmodule