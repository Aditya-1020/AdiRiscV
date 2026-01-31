import riscv_pkg::*;

module mem_wb_reg (
    input logic clk,
    input logic reset,
    input logic stall,
    input logic flush,
    input mem_wb_reg_t in, // from mem
    output mem_wb_reg_t out
);

    timeunit 1ns;
    timeprecision 1ps;

    always_ff @(posedge clk) begin
        if (reset || flush) begin
            out.alu_result <= '0;
            out.mem_data <= '0;
            out.rd_addr <= '0;
            out.ctrl <= '{
                reg_write: 1'b0,
                mem_read: 1'b0,
                mem_write: 1'b0,
                mem_to_reg: 1'b0,
                alu_src: 1'b0,
                is_branch: 1'b0,
                is_jump: 1'b0,
                is_jalr: 1'b0,
                alu_op: ALU_ADD,
                mem_op: MEM_WORD
            };
        end else if (!stall) begin
            out <= in;
        end

        //stall = 1 hold
    end


endmodule