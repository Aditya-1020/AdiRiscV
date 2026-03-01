// FPGA Top Module for AdiRiscV on Nexys A7-100T
`ifndef SYNTHESIS
timeunit 1ns;
timeprecision 1ps;
`endif

import riscv_pkg::*;

module fpga_top (
    input  logic        clk,
    input  logic        reset_n,      // Active-low reset (CPU_RESETN on Nexys A7)

    // LEDs
    output logic [3:0]  led,
    output logic [1:0]  led_r,
    output logic [1:0]  led_g,
    output logic [1:0]  led_b,

    // Switches and buttons
    input  logic [3:0]  sw,
    input  logic [3:0]  btn,

    // UART
    input  logic        uart_rxd,
    output logic        uart_txd
);

    // Reset synchroniser (two-flop)
    logic reset_sync_r1, reset_sync_r2, reset_sync;

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            reset_sync_r1 <= 1'b1;
            reset_sync_r2 <= 1'b1;
        end else begin
            reset_sync_r1 <= 1'b0;
            reset_sync_r2 <= reset_sync_r1;
        end
    end
    assign reset_sync = reset_sync_r2 | btn[0]; // btn[0] = BTNC = soft reset

    // Core debug outputs — driven through proper ports, not hierarchical refs
    logic [XLEN-1:0] debug_pc;
    logic [XLEN-1:0] debug_instr;
    logic            debug_stall;
    logic            debug_branch;
    logic            debug_load_use;
    logic            debug_ex_stall;
    logic            debug_alu_ready;

    riscv_pipelined_core core_inst (
        .clk          (clk),
        .reset        (reset_sync),
        // Debug ports
        .debug_pc     (debug_pc),
        .debug_instr  (debug_instr),
        .debug_stall  (debug_stall),
        .debug_branch (debug_branch),
        .debug_load_use (debug_load_use),
        .debug_ex_stall (debug_ex_stall),
        .debug_alu_ready(debug_alu_ready)
    );

    // Cycle counter (local — no need to reach into core)
    logic [7:0] cycle_counter;

    always_ff @(posedge clk) begin
        if (reset_sync)
            cycle_counter <= '0;
        else
            cycle_counter <= cycle_counter + 1'b1;
    end

    // LED output — switch-selectable debug view
    always_ff @(posedge clk) begin
        if (reset_sync) begin
            led <= 4'b0000;
        end else begin
            case (sw[1:0])
                2'b00: led <= debug_pc[5:2];          // PC word index
                2'b01: led <= debug_instr[10:7];       // rd field of current instr
                2'b10: led <= {3'b0, debug_branch};    // Branch taken flag
                2'b11: led <= cycle_counter[7:4];      // Rolling cycle count
            endcase
        end
    end

    // RGB LEDs — pipeline health indicators
    always_ff @(posedge clk) begin
        if (reset_sync) begin
            led_r <= 2'b00;
            led_g <= 2'b00;
            led_b <= 2'b00;
        end else begin
            // LED 0: pipeline flow
            led_r[0] <= debug_stall;                   // Red  = stalled
            led_g[0] <= !debug_stall;                  // Green = flowing
            led_b[0] <= debug_branch;                  // Blue  = branch taken

            // LED 1: hazard detail
            led_r[1] <= debug_load_use;                // Red  = load-use hazard
            led_g[1] <= debug_alu_ready;               // Green = ALU ready
            led_b[1] <= debug_ex_stall;                // Blue  = divider stall
        end
    end

    // UART loopback (stub — replace with real UART for future use)
    assign uart_txd = uart_rxd;

endmodule