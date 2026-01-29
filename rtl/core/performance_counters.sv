import riscv_pkg::*;

module performance_counters (
    input logic clk,
    input logic reset,
    
    // events
    input logic instruction_retired,
    input logic branch_taken,
    input logic branch_mispredicted,
    input logic load_use_stall,
    input logic div_stall,

    // counter outputs
    output logic [PERF_COUNTER_WIDTH-1:0] cycles,
    output logic [PERF_COUNTER_WIDTH-1:0] instructions,
    output logic [PERF_COUNTER_WIDTH-1:0] branches,
    output logic [PERF_COUNTER_WIDTH-1:0] branch_misses,
    output logic [PERF_COUNTER_WIDTH-1:0] stalls
);
    timeunit 1ns; timeprecision 1ps;

    always_ff @(posedge clk) begin
        if (reset) begin
            cycles <= '0;
            instructions <= '0;
            branches <= '0;
            branch_misses <= '0;
            stalls <= '0;
        end else begin
            cycles <= cycles + 1'b1;
            
            if (instruction_retired) 
                instructions <= instructions + 1'b1;
            
            if (branch_taken) 
                branches <= branches + 1'b1;
            
            if (branch_mispredicted) 
                branch_misses <= branch_misses + 1'b1;
            
            if (load_use_stall || div_stall) 
                stalls <= stalls + 1'b1;
        end
    end

    // Derived metrics
    real ipc; // instrs per cycle
    real branch_miss_rate;
    
    always_comb begin
        if (cycles > 0)
            ipc = real'(instructions) / real'(cycles);
        else
            ipc = 0.0;
            
        if (branches > 0)
            branch_miss_rate = real'(branch_misses) / real'(branches) * 100.0;
        else
            branch_miss_rate = 0.0;
    end

endmodule