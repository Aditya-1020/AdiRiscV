import riscv_pkg::*;

module alu (
    input logic clk,
    input logic reset,
    input logic [XLEN-1:0] a, 
    input logic [XLEN-1:0] b,
    input alu_op_e op,
    output logic zero,
    output logic [XLEN-1:0] result,
    output logic ready
);
    timeunit 1ns;
    timeprecision 1ps;

    logic [4:0] shift_amt;
    assign shift_amt = b[4:0];
    
    // M-MUL
    logic signed [63:0] mul_signed;
    logic [63:0] mul_unsigned;
    logic signed [63:0] mul_mixed;

    assign mul_signed = signed'(a) * signed'(b);
    assign mul_unsigned = a * b;
    assign mul_mixed = signed'(a) * signed'({1'b0, b}); // a signed, b unsigned

    // M-Divide
    logic div_start, div_is_signed, div_is_rem;
    logic [XLEN-1:0] div_result;
    logic div_done, div_busy;

    logic is_div_op;
    assign is_div_op = (op == ALU_DIV) || (op == ALU_DIVU) || (op == ALU_REM) || (op == ALU_REMU);

    logic div_op_last;
    always_ff @(posedge clk) begin
        if (reset) begin
            div_op_last <= 1'b0;
        end else begin
            div_op_last <= is_div_op;
        end
    end

    assign div_start = is_div_op && !div_op_last && !div_busy;
    assign div_is_signed = (op == ALU_DIV) || (op == ALU_REM);
    assign div_is_rem = (op == ALU_REM) || (op == ALU_REMU);

    divider divider_inst (
        .clk(clk),
        .reset(reset),
        .start(div_start),
        .is_signed(div_is_signed),
        .is_rem(div_is_rem),
        .dividend(a),
        .divisor(b),
        .result(div_result),
        .done(div_done),
        .busy(div_busy)
    );

    always_comb begin
        case (op)
            ALU_ADD: result = a + b;
            ALU_SUB: result = a - b;
            ALU_SLL: result = a << shift_amt;
            ALU_SLT: result = (signed'(a) < signed'(b)) ? 32'd1 : 32'd0;
            ALU_SLTU: result = (a < b) ? 32'd1 : 32'd0;
            ALU_XOR: result = a ^ b;
            ALU_SRL: result = a >> shift_amt;
            ALU_SRA: result = signed'(a) >>> shift_amt;
            ALU_OR: result = a | b;
            ALU_AND: result = a & b;
            ALU_PASS_A: result = a;
            ALU_PASS_B: result = b;
            
            // Multiply
            ALU_MUL: result = mul_signed[31:0];
            ALU_MULH: result = mul_signed[63:32];
            ALU_MULHSU: result = mul_mixed[63:32];
            ALU_MULHU: result = mul_unsigned[63:32];

            // Divide
            ALU_DIV, ALU_DIVU, ALU_REM, ALU_REMU: result = div_result;
            default: result = a + b;
        endcase

        zero = (result == 32'h0);
    end

    assign ready = is_div_op ? div_done : 1'b1;
endmodule