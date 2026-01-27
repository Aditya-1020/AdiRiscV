import riscv_pkg::*;

module btb (
    input logic clk,
    input logic reset,
    input logic [XLEN-1:0] pc_if,
    input logic lookup_en,
    input logic update_en,
    input logic [XLEN-1:0] pc_update,
    input logic [XLEN-1:0] target_update,
    input logic is_branch_or_jmp,

    output logic hit_valid,
    output logic [XLEN-1:0] target_predict,
    output logic [XLEN-1:0] pc_hit
    
);
    timeunit 1ns;
    timeprecision 1ps;


    // Works only when update enable && is_branch_or_jmp
    // updates valid index array with 1's
    // updates the tags with update_tags
    // updates target with update_targer

    // hit = look_en && valid[look-index] && (tag[look-inex] == look-tag)
    // target_pred = hit ? target[look-inex] : (pc_if + 4)
    // pchit =hit ? pcif : 0

endmodule