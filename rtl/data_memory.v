`timescale 1ps/1ps
`default_nettype none
`include "rtl/isa.vh"

module data_memory (
    input wire clk,
    input wire reset,
    input wire [`XLEN-1:0] address,
    input wire [`XLEN-1:0] WriteData,
    input wire [3:0] wr_en,
    input wire [1:0] load_type,
    input wire MemRead,
    output reg [`XLEN-1:0] ReadData
);

    reg [7:0] data_mem [0:`MEM_SIZE-1];

    wire [31:0] aligned_addr = address & ~32'h3;
    wire [1:0] byte_offset = address[1:0];
    
    wire [31:0] word_data = {data_mem[aligned_addr + 3], data_mem[aligned_addr + 2], data_mem[aligned_addr + 1], data_mem[aligned_addr + 0]};

    integer i;
    always @(*) begin
        if (!MemRead) begin
            ReadData = 32'h0;
        end else begin
            case (load_type)
                2'b00: begin // LB/LBU
                    case (byte_offset)
                        2'b00: ReadData = {{24{word_data[7]}}, word_data[7:0]};
                        2'b01: ReadData = {{24{word_data[15]}}, word_data[15:8]};
                        2'b10: ReadData = {{24{word_data[23]}}, word_data[23:16]};
                        2'b11: ReadData = {{24{word_data[31]}}, word_data[31:24]};
                    endcase
                end
                2'b01: begin // LH/LHU
                    case (byte_offset[1])
                        1'b0: ReadData = {{16{word_data[15]}}, word_data[15:0]};
                        1'b1: ReadData = {{16{word_data[31]}}, word_data[31:16]};
                    endcase
                end
                2'b10: begin // LW
                    ReadData = word_data;
                end
                default: ReadData = 32'h0;
            endcase
        end
    end
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < `MEM_SIZE; i = i + 1) begin
                data_mem[i] <= 0;
            end
        end else begin
            if (|wr_en) begin
                if (wr_en[0]) data_mem[address] <= WriteData[7:0];
                if (wr_en[1]) data_mem[address + 1] <= WriteData[15:8];
                if (wr_en[2]) data_mem[address + 2] <= WriteData[23:16];
                if (wr_en[3]) data_mem[address + 3] <= WriteData[31:24];
            end
        end
    end

endmodule