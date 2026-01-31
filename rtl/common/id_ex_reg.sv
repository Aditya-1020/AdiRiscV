import riscv_pkg::*;

module id_ex_reg (
    input logic clk,
    input logic reset,
    input logic stall, // hold values
    input logic flush, // insert bubble (NOP)
    input id_ex_reg_t in, // from id
    output id_ex_reg_t out // to ex
);

    timeunit 1ns;
    timeprecision 1ps;

    always_ff @(posedge clk) begin
        if (reset || flush) begin
            out.pc <= RESET_PC;
            out.rs1_data <= '0;
            out.rs2_data <= '0;
            out.funct3_for_branch <= '0;
            out.immediate <= '0;
            out.rs1_addr <= '0;
            out.rs2_addr <= '0;
            out.rd_addr <= '0;
            // Create a proper NOP control signal
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
                mem_op: MEM_WORD  // Explicit default
            };
            out.valid_id_ex <= 1'b0;
        end else if (!stall) begin
            out <= in;
        end

        // stall= 1 hodld
    end

endmodule