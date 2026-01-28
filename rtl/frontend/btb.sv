import riscv_pkg::*;

module btb (
    input logic clk,
    input logic reset,
    
    // llookup from IF stage
    input logic [XLEN-1:0] pc_lookup,
    input logic lookup_en,

    // From ex stage
    input logic update_en,
    input logic [XLEN-1:0] pc_update,
    input logic [XLEN-1:0] target_actual,
    input logic is_branch_or_jmp,

    output logic hit,
    output logic [XLEN-1:0] target_predicted
);
    timeunit 1ns;
    timeprecision 1ps;

    logic [BTB_SIZE-1:0] valid; // valid bit for each entry
    logic [BTB_TAG_WIDTH-1:0] tag_array [BTB_SIZE-1:0];
    logic [XLEN-1:0] target_array [BTB_SIZE-1:0];

    logic [BTB_INDEX_WIDTH-1:0] lookup_index;
    logic [BTB_TAG_WIDTH-1:0] lookup_tag;

    assign lookup_index = pc_lookup[BTB_INDEX_WIDTH+1:2];
    assign lookup_tag = pc_lookup[XLEN-1:BTB_INDEX_WIDTH+2];

    logic [BTB_INDEX_WIDTH-1:0] update_index;
    logic [BTB_TAG_WIDTH-1:0] update_tag;

    assign update_index = pc_update[BTB_INDEX_WIDTH+1:2];
    assign update_tag = pc_update[XLEN-1:BTB_INDEX_WIDTH+2];

    logic update_btb;
    assign update_btb = update_en && is_branch_or_jmp;
    
    // write to btb
    always_ff @(posedge clk) begin
        if (reset) begin
            valid <= '0;
        end else if (update_btb) begin
            valid[update_index] <= 1'b1;
            tag_array[update_index] <= update_tag;
            target_array[update_index] <= target_actual;
        end
    end
    
    // read from btb
    logic tag_match;
    assign tag_match = valid[lookup_index] && (tag_array[lookup_index] == lookup_tag);
    assign hit = lookup_en && tag_match;
    assign target_predicted = hit ? target_array[lookup_index] : pc_lookup + 32'd4;    

endmodule