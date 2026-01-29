import riscv_pkg::*;

module store_unit (
    input logic [XLEN-1:0] addr,
    input logic [XLEN-1:0] wdata,
    input mem_op_e mem_op,
    output logic [XLEN-1:0] wdata_aligned,
    output logic [3:0] byte_enable
);
    timeunit 1ns; timeprecision 1ps;

    logic [1:0] byte_offset;
    assign byte_offset = addr[1:0];

    always_comb begin
        wdata_aligned = wdata;
        byte_enable = '0;

        case (mem_op)
            MEM_BYTE: begin
            case (byte_offset)
                2'b00: begin
                    wdata_aligned = {24'b0, wdata[7:0]};
                    byte_enable = 4'b0001;
                end
                2'b01: begin
                    wdata_aligned = {16'b0, wdata[7:0], 8'b0};
                    byte_enable = 4'b0010;
                end
                2'b10: begin
                    wdata_aligned = {8'b0, wdata[7:0], 16'b0};
                    byte_enable = 4'b0100;
                end
                2'b11: begin
                    wdata_aligned = {wdata[7:0], 24'b0};
                    byte_enable = 4'b1000;
                end
            endcase
            end
            
            MEM_HALF: begin
                wdata_aligned = addr[1] ? {wdata[15:0], 16'b0} : {16'b0, wdata[15:0]};
                byte_enable = addr[1] ? 4'b1100 : 4'b0011;
            end

            MEM_WORD: begin
                wdata_aligned = wdata;
                byte_enable = 4'b1111;
            end

            default: begin
                wdata_aligned = wdata;
                byte_enable = 4'b1111;
            end
        endcase
        end
        
endmodule