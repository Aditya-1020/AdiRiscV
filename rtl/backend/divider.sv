// Iterative non-restoring division
import riscv_pkg::*;

module divider(
    input logic clk,
    input logic reset,
    input logic start,
    input logic is_signed,
    input logic is_rem,
    input logic [XLEN-1:0] dividend,
    input logic [XLEN-1:0] divisor,
    
    output logic [XLEN-1:0] result, // return quotient
    output logic [XLEN-1:0] remainder_out,
    output logic done,
    output logic busy
);
    timeunit 1ns;
    timeprecision 1ps;

    typedef enum logic [1:0] { IDLE, COMPUTE, RESTORE, DONE } state_t;
    state_t state, next_state;
    
    // extra 1 bit for sign (Acuumulator/Remainder)
    logic signed [XLEN:0] reg_A;
    logic [XLEN-1:0] reg_Q; // dividend
    logic [XLEN-1:0] reg_M; // divisor
    logic [COUNT_SIZE_DIVISOR:0] count;

    // handle sing
    logic sign_dividend, sign_divisor;
    logic [XLEN-1:0] abs_dividend, abs_divisor;

    //absolute val for signed division
    assign abs_dividend = (is_signed && dividend[XLEN-1]) ? -dividend : dividend; // [XLEN-1:0]
    assign abs_divisor = (is_signed && divisor[XLEN-1]) ? -divisor : divisor; // [XLEN-1:0]

    // ALU reg
    logic [XLEN:0] shifted_A;
    logic [XLEN:0] alu_out;
    logic op_add;

    // shift: combine A and MSB of Q
    assign shifted_A = {reg_A[XLEN-1:0], reg_Q[XLEN-1]};
    // if a neg (1) add else sub
    assign op_add = reg_A[XLEN];

    assign alu_out = op_add ? shifted_A + {1'b0, reg_M} : shifted_A - {1'b0, reg_M}; // add or sub

    always_ff @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            reg_A <= '0;
            reg_Q <= '0;
            reg_M <= '0;
            count <= '0;
            busy <= 1'b0;
            done <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        reg_Q <= abs_dividend;
                        reg_M <= abs_divisor;
                        reg_A <= '0; // Acc always starts 0
                        count <= XLEN;

                        sign_dividend <= is_signed && dividend[XLEN-1];
                        sign_divisor <= is_signed && divisor[XLEN-1];

                        busy <= 1'b1;
                        state <= COMPUTE;
                    end
                end
                
                COMPUTE: begin
                    // update A with ALU res
                    reg_A <= alu_out;
                    reg_Q <= {reg_Q[XLEN-2:0], ~alu_out[XLEN]}; // aluout neg bit=0, if pos bit=1

                    count <= count - 1;
                    if (count == 1) state <= RESTORE;
                end

                RESTORE: begin
                    // if remainder neg restore it
                    if (reg_A[XLEN]) reg_A <= reg_A + {1'b0, reg_M};
                    state <= DONE;
                end

                DONE: begin
                    busy <= 1'b0;
                    done <= 1'b1;
                    state <= IDLE;
                end
            endcase
        end
    end

    // Output
    // Quosient sign neg if sign differs
    logic sign_result, sign_remainder;
    assign sign_result = sign_dividend ^ sign_divisor;
    assign sign_remainder = sign_dividend; // same as divided

    // mux with explicit 2s complement negation
    assign result = sign_result ? -reg_Q : reg_Q;
    assign remainder_out = sign_remainder ? -reg_A[XLEN-1:0] : reg_A[XLEN-1:0];

endmodule