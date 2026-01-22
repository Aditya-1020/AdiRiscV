import riscv_pkg::*;

module dmem(
    input logic clk,
    input logic [XLEN-1:0] addr,
    input logic [XLEN-1:0] wdata,
    input logic wr_en,
    input logic rd_en,
    input mem_op_e mem_op,
    output logic [XLEN-1:0] rdata
);
    timeunit 1ns;
    timeprecision 1ps;

    // FPGA BRAM attributes for Xilinx synthesis
    (* ram_style = "block" *) logic [7:0] mem [0:DMEM_SIZE-1];
    
    // Word-aligned address and offset
    logic [XLEN-1:0] word_addr;
    logic [1:0] byte_offset;
    logic [31:0] word;
    
    assign word_addr = {addr[XLEN-1:2], 2'b00};
    assign byte_offset = addr[1:0];

    // Registered output for BRAM inference
    logic [31:0] read_word;
    logic [31:0] rdata_reg;

    // SYNCHRONOUS READ (required for BRAM)
    always_ff @(posedge clk) begin
        if (rd_en) begin
            // Read full 32-bit word (little-endian)
            read_word <= {mem[word_addr+3], mem[word_addr+2], 
                         mem[word_addr+1], mem[word_addr]};
        end
    end

    // Combinational logic for byte/halfword extraction and sign extension
    always_comb begin
        rdata_reg = 32'h0;
        
        if (rd_en) begin
            case (mem_op)
                MEM_BYTE: begin // LB (sign-extended)
                    case (byte_offset)
                        2'b00: rdata_reg = {{24{read_word[7]}},  read_word[7:0]};
                        2'b01: rdata_reg = {{24{read_word[15]}}, read_word[15:8]};
                        2'b10: rdata_reg = {{24{read_word[23]}}, read_word[23:16]};
                        2'b11: rdata_reg = {{24{read_word[31]}}, read_word[31:24]};
                    endcase
                end

                MEM_HALF: begin // LH (sign-extended)
                    case (byte_offset[1])
                        1'b0: rdata_reg = {{16{read_word[15]}}, read_word[15:0]};
                        1'b1: rdata_reg = {{16{read_word[31]}}, read_word[31:16]};
                    endcase
                end

                MEM_WORD: rdata_reg = read_word; // LW

                MEM_BYTE_U: begin // LBU (zero-extended)
                    case (byte_offset)
                        2'b00: rdata_reg = {24'h0, read_word[7:0]};
                        2'b01: rdata_reg = {24'h0, read_word[15:8]};
                        2'b10: rdata_reg = {24'h0, read_word[23:16]};
                        2'b11: rdata_reg = {24'h0, read_word[31:24]};
                    endcase
                end

                MEM_HALF_U: begin // LHU (zero-extended)
                    case (byte_offset[1])
                        1'b0: rdata_reg = {16'h0, read_word[15:0]};
                        1'b1: rdata_reg = {16'h0, read_word[31:16]};
                    endcase
                end
                
                default: rdata_reg = 32'h0;
            endcase
        end
    end
    
    assign rdata = rdata_reg;
    
    // WRITE (separate process for BRAM inference)
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
                
                default: ; // MEM_BYTE_U, MEM_HALF_U not used for stores
            endcase
        end
    end

endmodule