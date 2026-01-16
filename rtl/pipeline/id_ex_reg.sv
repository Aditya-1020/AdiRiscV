import riscv_pkg::*;

module id_ex_stage (
    input logic clk,
    input logic reset,
    input logic stall, // hold values
    input logic flush // insert bubble (NOP)
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
            out.ctrl <= '0;
            out.valid_id_ex <= 1'b0;
        end else if (!stall) begin
            out <= in;
        end

        // stall= 1 hodld
    end

endmodule