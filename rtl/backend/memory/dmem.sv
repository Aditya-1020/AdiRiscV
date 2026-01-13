import riscv_pkg::*;

module dmem(
    input logic clk,
    // input logic reset,
    input logic [XLEN-1:0] addr,
    input logic [XLEN-1:0] wdata,
    input logic wr_en,
    input logic rd_en,
    input mem_op_e mem_op,
    output logic [XLEN-1:0] rdata
);
    timeunit 1ns;
    timeprecision 1ps;

    logic [7:0] mem [0:DMEM_SIZE-1];
    // (* ram_style = "block" *) logic [7:0] mem_array [0:DMEM_SIZE-1];

    // word aligned address
    logic [XLEN-1:0] word_addr;
    logic [1:0] byte_offset;
    logic [31:0] word;

    assign word_addr = {addr[XLEN-1:2], 2'b00};
    assign byte_offset = addr[1:0];

    // READ
    always_comb begin
        rdata = 32'h0;
        word = 32'h0;

        if (rd_en) begin    
            word = {mem[word_addr+3], mem[word_addr+2], mem[word_addr+1], mem[word_addr]}; // Read full 32bit word (little-endian)
            
            case (mem_op)
                MEM_BYTE: begin // LB
                    case (byte_offset)
                        2'b00: rdata = {{24{word[7]}},  word[7:0]};
                        2'b01: rdata = {{24{word[15]}}, word[15:8]};
                        2'b10: rdata = {{24{word[23]}}, word[23:16]};
                        2'b11: rdata = {{24{word[31]}}, word[31:24]};
                    endcase
                end

                MEM_HALF: begin // LH
                    case (byte_offset[1])
                        1'b0: rdata = {{16{word[15]}}, word[15:0]};
                        1'b1: rdata = {{16{word[31]}}, word[31:16]};
                    endcase
                end

                MEM_WORD: rdata = word; // LW

                MEM_BYTE_U: begin // LBU
                    case (byte_offset)
                        2'b00: rdata = {24'h0, word[7:0]};
                        2'b01: rdata = {24'h0, word[15:8]};
                        2'b10: rdata = {24'h0, word[23:16]};
                        2'b11: rdata = {24'h0, word[31:24]};
                    endcase
                end

                MEM_HALF_U: begin // LHU
                    case (byte_offset[1])
                        1'b0: rdata = {16'h0, word[15:0]};
                        1'b1: rdata = {16'h0, word[31:16]};
                    endcase
                end
                default: ; // hold
            endcase
        end else begin
            rdata = 32'h0; // Explicit rdata when rd= 0
        end
    end
    
    
    // Write
    always_ff @(posedge clk) begin
        if (wr_en) begin
            case (mem_op)
                MEM_BYTE: begin
                    case (byte_offset)
                        2'b00: mem[word_addr+0] <= wdata[7:0];
                        2'b01: mem[word_addr+1] <= wdata[7:0];
                        2'b10: mem[word_addr+2] <= wdata[7:0];
                        2'b11: mem[word_addr+3] <= wdata[7:0];
                    endcase
                end
                
                MEM_HALF: begin
                    case (byte_offset[1])
                        1'b0: begin
                            mem[word_addr+0] <= wdata[7:0];
                            mem[word_addr+1] <= wdata[15:8];
                        end
                        1'b1: begin
                            mem[word_addr+2] <= wdata[7:0];
                            mem[word_addr+3] <= wdata[15:8];
                        end
                    endcase
                end
                
                MEM_WORD: begin
                    mem[word_addr+0] <= wdata[7:0];
                    mem[word_addr+1] <= wdata[15:8];
                    mem[word_addr+2] <= wdata[23:16];
                    mem[word_addr+3] <= wdata[31:24];
                end
                
                default: ; // MEM_BYTE_U, MEM_HALF_U ignored
            endcase
        end
    end

endmodule