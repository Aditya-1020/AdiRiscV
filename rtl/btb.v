// branch target buffer
`timescale 1ps/1ps
`default_nettype none
`include "rtl/isa.vh"

module btb (
    input wire clk,
    input wire reset,
    input wire [`XLEN-1:0] pc_if,
    input wire lookup_enable,
    input wire update_enable,
    input wire [`XLEN-1:0] pc_update,
    input wire [`XLEN-1:0] target_update,
    input wire is_branch_or_jump,

    output wire hit_valid,
    output wire [`XLEN-1:0] target_predict,
    output wire [`XLEN-1:0] pc_hit
);

    // BTB Entry Structure
    reg valid [`BTB_SIZE-1:0];
    reg [`BTB_CACHE_WIDTH-1:0] tag [`BTB_SIZE-1:0]; // upper pc
    reg [`XLEN-1:0] target [`BTB_SIZE-1:0];

    // tag extract
    wire [`BTB_INDEX_WIDTH-1:0] lookup_index = pc_if[`BTB_INDEX_WIDTH+1:2];
    wire [`BTB_INDEX_WIDTH-1:0] update_index = pc_update[`BTB_INDEX_WIDTH+1:2];
    wire [`ICACHE_TAG_WIDTH-1:0] lookup_tag = pc_if[31:`BTB_INDEX_WIDTH+2];
    wire [`ICACHE_TAG_WIDTH-1:0] update_tag = pc_update[31:`BTB_INDEX_WIDTH+2];

    integer i;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < `BTB_SIZE; i = i + 1) begin
                valid[i] <= 1'b0;
                tag[i] <= {`BTB_CACHE_WIDTH{1'b0}};
                target[i] <= {`XLEN{1'b0}};
            end
        end else if (update_enable && is_branch_or_jump) begin
            valid[update_index] <= 1'b1;
            tag[update_index] <= update_tag;
            target[update_index] <= target_update;
        end
    end

    wire hit = lookup_enable && valid[lookup_index] && (tag[lookup_index] == lookup_tag);
    assign hit_valid = hit;
    assign target_predict = hit ? target[lookup_index] : (pc_if + 4);
    assign pc_hit = hit ? pc_if : 0;

endmodule