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
            out.ctrl <= '0;
            out.valid_ex_mem <= 1'b0;
        end else if (!stall) begin
            out <= in;
        end
        // stall=1 hold
    end
    
endmodule