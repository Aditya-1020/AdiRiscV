`timescale 1ps/1ps
`default_nettype none
`include "rtl/isa.vh"

module branch_predictor (
    input wire clk,
    input wire reset,
    input wire [`XLEN-1:0] pc_if,
    
    input wire predict_enable,
    input wire update_enable,
    input wire [`XLEN-1:0] pc_update,
    input wire branch_taken,
    input wire is_branch,

    output reg prediction,
    output reg [1:0] predict_strength
);

    reg [1:0] predict_table [0:`BTB_SIZE-1]; // 2 bit counters

    wire [`BTB_INDEX_WIDTH-1:0] predict_index = pc_if[`BTB_INDEX_WIDTH+1:2];
    wire [`BTB_INDEX_WIDTH-1:0] update_index = pc_update[`BTB_INDEX_WIDTH+1:2];

    integer i;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < `BTB_SIZE; i = i + 1) begin
                predict_table[i] <= 2'b01;
            end
        end else if (update_enable && is_branch) begin
            case (predict_table[update_index])
                2'b00: predict_table[update_index] <= branch_taken ? 2'b01 : 2'b00;
                2'b01: predict_table[update_index] <= branch_taken ? 2'b10 : 2'b00;
                2'b10: predict_table[update_index] <= branch_taken ? 2'b11 : 2'b00;
                2'b11: predict_table[update_index] <= branch_taken ? 2'b11 : 2'b10;
                default: predict_table[update_index] <= 2'b10;
            endcase
        end
    end

    assign predict_strength = predict_enable ? predict_table[predict_index] : 2'b00;
    assign prediction = predict_enable ? predict_strength[1] : 1'b0;

endmodule