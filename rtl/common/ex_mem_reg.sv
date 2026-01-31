import riscv_pkg::*;

module ex_mem_reg (
    input logic clk,
    input logic reset,
    input logic stall,
    input logic flush,
    input ex_mem_reg_t in, // from ex
    output ex_mem_reg_t out
);

    timeunit 1ns;
    timeprecision 1ps;

    always_ff @(posedge clk) begin
        if (reset || flush) begin
            out.alu_result <= '0;
            out.rs2_data_str <= '0;
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
        // stall=1 hold
    end
    
endmodule