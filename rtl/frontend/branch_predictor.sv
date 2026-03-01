`ifndef SYNTHESIS
timeunit 1ns;
timeprecision 1ps;
`endif

import riscv_pkg::*;

module branch_predictor (
    input logic clk,
    input logic reset,
    
    // Prediction from IF
    input logic [XLEN-1:0] pc,
    input logic [XLEN-1:0] instruction,
    input logic predict_en,

    // RAS
    input logic ras_valid,
    input logic [XLEN-1:0] ras_target,

    // BTB
    input logic btb_hit,
    input logic [XLEN-1:0] btb_target,

    // Update from EX
    input logic update_en,
    input logic [XLEN-1:0] update_pc,
    input logic actual_taken,
    input logic [XLEN-1:0] actual_target,   // FIX: was incorrectly declared as 1-bit `logic`
    input logic is_branch,
    
    output branch_pred_t prediction_out
);

    // 2-bit saturating counters
    localparam int PHT_SIZE          = 256;
    localparam int PHT_INDEX_WIDTH   = $clog2(PHT_SIZE);
    localparam int HISTORY_BUFFER_SIZE = 8;

    branch_pred_state_e pht [PHT_SIZE-1:0];

    logic [HISTORY_BUFFER_SIZE-1:0] global_history;

    // Indices
    logic [PHT_INDEX_WIDTH-1:0] predict_index;
    logic [PHT_INDEX_WIDTH-1:0] update_index;

    // G-share predict index
    assign predict_index = pc[PHT_INDEX_WIDTH+1:2] ^ global_history[PHT_INDEX_WIDTH-1:0];
    assign update_index  = update_pc[PHT_INDEX_WIDTH+1:2];

    // Update global history on branch resolve
    always_ff @(posedge clk) begin
        if (reset) begin
            global_history <= '0;
        end else if (update_en && is_branch) begin
            global_history <= {global_history[HISTORY_BUFFER_SIZE-2:0], actual_taken};
        end
    end

    // Instruction decode
    opcode_e opcode;
    logic is_jal, is_jalr, is_branch_instr;
    logic [4:0] rd, rs1;

    assign opcode          = opcode_e'(instruction[6:0]);
    assign rd              = instruction[11:7];
    assign rs1             = instruction[19:15];
    assign is_jal          = (opcode == OP_JAL);
    assign is_jalr         = (opcode == OP_JALR);
    assign is_branch_instr = (opcode == OP_BRANCH);

    // RAS return detection
    localparam logic [4:0] RA_REG = 5'd1; // x1
    localparam logic [4:0] T0_REG = 5'd5; // x5

    logic is_return;
    assign is_return = is_jalr && (rs1 == RA_REG || rs1 == T0_REG) && (rd == 5'd0);

    // PHT lookup
    branch_pred_state_e current_state;
    logic predict_taken_pht;

    assign current_state    = pht[predict_index];
    assign predict_taken_pht = (current_state == PRED_WEAK_TAKEN) ||
                               (current_state == PRED_STRONG_TAKEN);

    // Prediction priority: RAS > JAL/JALR (BTB) > conditional branch (BTB+PHT)
    logic take_ras, take_jal, take_jalr, take_cond_branch;
    assign take_ras         = is_return && ras_valid;
    assign take_jal         = is_jal && btb_hit;
    assign take_jalr        = is_jalr && !is_return && btb_hit;
    assign take_cond_branch = is_branch_instr && predict_taken_pht && btb_hit;

    always_comb begin
        prediction_out.predict_taken  = 1'b0;
        prediction_out.predict_target = pc + 32'd4;

        if (!predict_en) begin
            prediction_out.predict_taken  = 1'b0;
            prediction_out.predict_target = pc + 32'd4;
        end else if (take_ras) begin
            prediction_out.predict_taken  = 1'b1;
            prediction_out.predict_target = ras_target;
        end else if (take_jal) begin
            prediction_out.predict_taken  = 1'b1;
            prediction_out.predict_target = btb_target;
        end else if (take_jalr) begin
            prediction_out.predict_taken  = 1'b1;
            prediction_out.predict_target = btb_target;
        end else if (take_cond_branch) begin
            prediction_out.predict_taken  = 1'b1;
            prediction_out.predict_target = btb_target;
        end
    end

    // PHT update (saturating counter)
    logic counter_update_en;
    assign counter_update_en = update_en && is_branch;

    always_ff @(posedge clk) begin
        if (reset) begin
            for (int i = 0; i < PHT_SIZE; i++) begin
                pht[i] <= PRED_WEAK_NOT_TAKEN;
            end
        end else if (counter_update_en) begin
            case (pht[update_index])
                PRED_STRONG_NOT_TAKEN: begin
                    if (actual_taken)
                        pht[update_index] <= PRED_WEAK_NOT_TAKEN;
                    // else: stay saturated — no change needed
                end
                PRED_WEAK_NOT_TAKEN: begin
                    pht[update_index] <= actual_taken ? PRED_WEAK_TAKEN : PRED_STRONG_NOT_TAKEN;
                end
                PRED_WEAK_TAKEN: begin
                    pht[update_index] <= actual_taken ? PRED_STRONG_TAKEN : PRED_WEAK_NOT_TAKEN;
                end
                PRED_STRONG_TAKEN: begin
                    if (!actual_taken)
                        pht[update_index] <= PRED_WEAK_TAKEN;
                    // else: stay saturated — no change needed
                end
                default: pht[update_index] <= PRED_WEAK_NOT_TAKEN;
            endcase
        end
    end

endmodule