// FPGA Top Module for AdiRiscV on Arty A7-100T
import riscv_pkg::*;

module fpga_top (
    input  logic clk,
    input  logic reset_n,      // Active-low reset
    
    // LEDs for output
    output logic [3:0] led,
    output logic [1:0] led_r,
    output logic [1:0] led_g,
    output logic [1:0] led_b,
    
    input  logic [3:0] sw, // Switches for input
    input  logic [3:0] btn,// Buttons for control
    
    // UART (later)
    input  logic uart_rxd,
    output logic uart_txd
);

    timeunit 1ns;
    timeprecision 1ps;

    // Internal signals
    logic reset_sync;
    logic clk_core;
    
    // Debug signals
    logic [XLEN-1:0] pc_monitor;
    logic [XLEN-1:0] instr_monitor;
    logic [4:0] hazard_counter;
    logic [7:0] cycle_counter;

    // Clock and Reset Management
    
    // Synchronize reset
    logic reset_sync_r1, reset_sync_r2;
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            reset_sync_r1 <= 1'b1;
            reset_sync_r2 <= 1'b1;
        end else begin
            reset_sync_r1 <= 1'b0;
            reset_sync_r2 <= reset_sync_r1;
        end
    end
    assign reset_sync = reset_sync_r2;
    
    // Clock for core (could add PLL/MMCM here for different frequencies)
    assign clk_core = clk;  // Direct 100MHz for now

    // Core Instantiation
    
    riscv_pipelined_core core_inst (
        .clk(clk_core),
        .reset(reset_sync | btn[0])  // Reset via button or power-on
    );

    // Debug Monitoring
    
    // Monitor PC and instruction
    assign pc_monitor = core_inst.if_stage_inst.pc;
    assign instr_monitor = core_inst.if_stage_inst.instruction;
    
    // Count cycles
    always_ff @(posedge clk_core) begin
        if (reset_sync) begin
            cycle_counter <= '0;
        end else begin
            cycle_counter <= cycle_counter + 1'b1;
        end
    end
    
    // Count hazards
    always_ff @(posedge clk_core) begin
        if (reset_sync) begin
            hazard_counter <= '0;
        end else if (core_inst.hazard_unit_inst.load_use_hazard && hazard_counter != 5'h1F) begin
            hazard_counter <= hazard_counter + 1'b1;
        end
    end

    // LED Output Mapping
    
    // Basic LEDs show pipeline activity
    always_ff @(posedge clk_core) begin
        if (reset_sync) begin
            led <= 4'b0000;
        end else begin
            case (sw[1:0])
                2'b00: led <= pc_monitor[5:2];              // Show PC[5:2]
                2'b01: led <= instr_monitor[10:7];          // Show instruction bits
                2'b10: led <= {3'b0, core_inst.branch_taken}; // Show branch status
                2'b11: led <= cycle_counter[7:4];           // Show cycle count
            endcase
        end
    end
    
    // RGB LEDs show pipeline stage status
    always_ff @(posedge clk_core) begin
        if (reset_sync) begin
            led_r <= 2'b00;
            led_g <= 2'b00;
            led_b <= 2'b00;
        end else begin
            // LED0: Pipeline stall indicator
            led_r[0] <= core_inst.pc_stall;                 // Red when stalled
            led_g[0] <= core_inst.if_id_reg_out.valid_if_id && !core_inst.pc_stall;  // Green when running
            led_b[0] <= core_inst.branch_taken;             // Blue on branch
            
            // LED1: Hazard indicators
            led_r[1] <= core_inst.hazard_unit_inst.load_use_hazard;  // Red for load-use
            led_g[1] <= core_inst.ex_stage_inst.alu_ready;           // Green when ALU ready
            led_b[1] <= core_inst.ex_stage_inst.ex_stall;            // Blue when div stall
        end
    end

    
    // UART Interface (stub for future expansion)
    
    assign uart_txd = uart_rxd;  // Loopback for now

    // Synthesis Directives
    
    // Prevent optimization of critical debug signals
    (* keep = "true" *) logic keep_pc;
    (* keep = "true" *) logic keep_instr;
    
    assign keep_pc = |pc_monitor;
    assign keep_instr = |instr_monitor;

endmodule