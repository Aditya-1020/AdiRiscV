import riscv_pkg::*;

module memory_controller (
    input logic clk,
    input logic reset,

    // Instr mem interface (from IF)
    input logic [XLEN-1:0] imem_addr,
    output logic [XLEN-1:0] imem_rdata,

    // Data mem interface (from LSU)
    input logic [XLEN-1:0] dmem_addr,
    input logic [XLEN-1:0] dmem_wdata,
    input logic [3:0] dmem_byte_en,
    input logic dmem_wr_en,
    input logic dmem_rd_en,
    output logic [XLEN-1:0] dmem_rdata
);
    timeunit 1ns; timeprecision 1ps;

    localparam DMEM_W = 8;
    localparam BYTES_PER_WORD = 4;

    (* ram_style = "block" *) logic [XLEN-1:0] imem [0:IMEM_SIZE-1];
    (* ram_style = "block" *) logic [DMEM_W-1:0] dmem [0:DMEM_SIZE-1];

    always_ff @(posedge clk) begin
        if (reset) begin
            // for (int i = 0; i < IMEM_SIZE; i++) imem[i] <= NOP_INSTR;
            for (int i = 0; i < DMEM_SIZE; i++) dmem[i] <= '0;
        end
    end
    
    logic [WORD_ADDR_WIDTH-1:0] imem_word_addr;
    assign imem_word_addr = imem_addr[WORD_ADDR_WIDTH+1:2];

    logic imem_rdata_en;
    assign imem_rdata_en = imem_word_addr < IMEM_SIZE;

    // NOP for out of bound access
    assign imem_rdata = imem_rdata_en ? imem[imem_word_addr] : NOP_INSTR;

    // Dmem read
    logic [BYTE_ADDR_WIDTH-1:0] dmem_byte_addr;
    assign dmem_byte_addr = dmem_addr[BYTE_ADDR_WIDTH-1:0];

    logic dmem_in_bounds;
    assign dmem_in_bounds = dmem_byte_addr < (DMEM_SIZE - 3);

    logic dmem_rd_en_qual;
    assign dmem_rd_en_qual = dmem_rd_en && dmem_in_bounds;
    
    // Read 4 bytes
    // assign dmem_rdata = dmem_rd_en_qual ? {>>{dmem[dmem_byte_addr +: BYTES_PER_WORD]}} : '0;

    always_comb begin
        if (dmem_rd_en_qual) begin
            dmem_rdata = {dmem[dmem_byte_addr + 3],
                          dmem[dmem_byte_addr + 2],
                          dmem[dmem_byte_addr + 1],
                          dmem[dmem_byte_addr + 0]};
        end else begin
            dmem_rdata = '0;
        end
    end

    logic dmem_wr_en_qual;
    assign dmem_wr_en_qual = dmem_wr_en && dmem_in_bounds;

    // dmem write
    always_ff @(posedge clk) begin
        if (dmem_wr_en_qual) begin
            for (int i = 0; i < BYTES_PER_WORD; i++) begin
                if (dmem_byte_en[i])
                    dmem[dmem_byte_addr + i] <= dmem_wdata[8*i +: 8];
            end
        end
    end

endmodule