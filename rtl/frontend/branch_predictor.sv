import riscv_pkg::*;

module branch_predictor (
    input logic clk,
    input logic reset,
    
    // Prediction from if
    input logic [XLEN-1:0] pc,
    input logic [XLEN-1:0] instruction,
    input logic predict_en,

    // Ras
    input logic ras_valid,
    input logic [XLEN-1:0] ras_target,

    // btb
    input logic btb_hit,
    input logic [XLEN-1:0] btb_target,

    // update from ex
    input logic update_en,
    input logic [XLEN-1:0] update_pc,
    input logic actual_taken,
    input logic actual_target,
    input logic is_branch,
    
    output branch_pred_t prediction_out;
);

    branch_pred_state_e state, next_state;

    

endmodule