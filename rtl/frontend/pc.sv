import riscv_pkg::*;

module pc(
    input logic clk,
    input logic reset,
    
    input logic pc_en,
    input logic pc_stall,

    // brach/jump from ex
    input logic branch_taken,
    input logic [XLEN-1:0] branch_target,

    // branch prediction (LATER)
    input logic predict_taken,
    input logic [XLEN-1:0] predict_target,

    output logic [XLEN-1:0] pc,
    output logic [XLEN-1:0] pc_plus4
);
    timeunit 1ns; timeprecision 1ps;

    logic [XLEN-1:0] pc_next;
    assign pc_plus4 = pc + 32'd4;

    always_comb begin
        if (branch_taken) begin
            pc_next = branch_target;
        end else if (predict_taken) begin
            pc_next = predict_target;
        end else begin
            pc_next = pc_plus4;
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            pc <= RESET_PC;
        end else if (pc_en && !pc_stall) begin
            pc <= pc_next;
        end
    end

endmodule