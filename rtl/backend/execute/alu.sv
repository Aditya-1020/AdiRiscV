import riscv_pkg::*;

module alu (
    input logic [XLEN-1:0] a, 
    input logic [XLEN-1:0] b,
    input alu_op_e op,
    output logic zero,
    output logic [XLEN-1:0] result
);
    timeunit 1ns;
    timeprecision 1ps;

    logic [4:0] shift_amt;
    assign shift_amt = b[4:0];

    // logic signed [XLEN-1:0] signed_a = signed'(a);
    // logic signed [XLEN-1:0] signed_b = signed'(b);


    /*NOTE: 
    - for some reason simulation only works with inline cassting ? 
    - But assigned casting waht i tried works in synthesis ? 
    */
    
    always_comb begin
        case (op)
            ALU_ADD : result = a + b;
            ALU_SUB : result = a - b;
            ALU_SLL : result = a << shift_amt;
            ALU_SLT : result = (signed'(a) < signed'(b)) ? 32'd1 : 32'd0;
            ALU_SLTU : result = (a < b) ? 32'd1 : 32'd0;
            ALU_XOR : result = a ^ b;
            ALU_SRL : result = a >> shift_amt;
            ALU_SRA : result = signed'(a) >>> shift_amt;
            ALU_OR : result = a | b;
            ALU_AND : result = a & b;
            ALU_PASS_A : result = a;
            ALU_PASS_B : result = b;
            default: result = a + b;
        endcase

        zero = (result == 32'h0);
    end
endmodule