`ifndef SYNTHESIS
timeunit 1ns;
timeprecision 1ps;
`endif

import riscv_pkg::*;

`ifndef IMEM_INIT_FILE
    `define IMEM_INIT_FILE "programs/TEST.hex"
`endif

module memory_controller (
    input logic clk,
    input logic reset,

    // Instruction memory interface (from IF)
    input  logic [XLEN-1:0] imem_addr,
    output logic [XLEN-1:0] imem_rdata,

    // Data memory interface (from LSU)
    input  logic [XLEN-1:0] dmem_addr,
    input  logic [XLEN-1:0] dmem_wdata,
    input  logic [3:0]      dmem_byte_en,
    input  logic             dmem_wr_en,
    input  logic             dmem_rd_en,
    output logic [XLEN-1:0] dmem_rdata
);

    localparam DMEM_W       = 8;
    localparam BYTES_PER_WORD = 4;

    (* ram_style = "block" *) logic [XLEN-1:0]  imem [0:IMEM_SIZE-1];
    (* ram_style = "block" *) logic [DMEM_W-1:0] dmem [0:DMEM_SIZE-1];

    
    // IMEM initialisation
    initial begin
        // Zero-fill first so unspecified locations are NOPs (0x00000013)
        for (int i = 0; i < IMEM_SIZE; i++) imem[i] = NOP_INSTR;
        $readmemh(`IMEM_INIT_FILE, imem);
    end

    // DMEM always starts zeroed
    initial begin
        for (int i = 0; i < DMEM_SIZE; i++) dmem[i] = '0;
    end

    // IMEM read (combinational — single-cycle latency)
    logic [WORD_ADDR_WIDTH-1:0] imem_word_addr;
    assign imem_word_addr = imem_addr[WORD_ADDR_WIDTH+1:2];

    logic imem_in_bounds;
    assign imem_in_bounds = (imem_word_addr < IMEM_SIZE);

    assign imem_rdata = imem_in_bounds ? imem[imem_word_addr] : NOP_INSTR;

    // DMEM read (combinational)
    logic [BYTE_ADDR_WIDTH-1:0] dmem_byte_addr;
    assign dmem_byte_addr = dmem_addr[BYTE_ADDR_WIDTH-1:0];

    logic dmem_in_bounds;
    assign dmem_in_bounds = (dmem_byte_addr < (DMEM_SIZE - 3));

    always_comb begin
        if (dmem_rd_en && dmem_in_bounds) begin
            dmem_rdata = {dmem[dmem_byte_addr + 3],
                          dmem[dmem_byte_addr + 2],
                          dmem[dmem_byte_addr + 1],
                          dmem[dmem_byte_addr + 0]};
        end else begin
            dmem_rdata = '0;
        end
    end

    // DMEM write (synchronous, byte-enable)
    always_ff @(posedge clk) begin
        // No reset needed — dmem initialised above; reset would cost a lot of LUTs
        if (dmem_wr_en && dmem_in_bounds) begin
            for (int i = 0; i < BYTES_PER_WORD; i++) begin
                if (dmem_byte_en[i])
                    dmem[dmem_byte_addr + i] <= dmem_wdata[8*i +: 8];
            end
        end
    end

endmodule