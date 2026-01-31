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
    
    output logic [XLEN-1:0] result,
    output logic [XLEN-1:0] remainder_out,
    output logic done,
    output logic busy
);
    timeunit 1ns;
    timeprecision 1ps;

    typedef enum logic [1:0] { IDLE, COMPUTE, RESTORE, DONE } state_t;
    state_t state;
    
    logic signed [XLEN:0] reg_A;
    logic [XLEN-1:0] reg_Q;
    logic [XLEN-1:0] reg_M;
    logic [COUNT_SIZE_DIVISOR:0] count;

    logic sign_dividend, sign_divisor;
    logic [XLEN-1:0] abs_dividend, abs_divisor;

    assign abs_dividend = (is_signed && dividend[XLEN-1]) ? -dividend : dividend;
    assign abs_divisor = (is_signed && divisor[XLEN-1]) ? -divisor : divisor;

    logic [XLEN:0] shifted_A;
    logic [XLEN:0] alu_out;
    logic op_add;

    assign shifted_A = {reg_A[XLEN-1:0], reg_Q[XLEN-1]};
    assign op_add = reg_A[XLEN];
    assign alu_out = op_add ? shifted_A + {1'b0, reg_M} : shifted_A - {1'b0, reg_M};

    // Output registers for stable outputs
    logic [XLEN-1:0] final_quotient;
    logic [XLEN-1:0] final_remainder;

    always_ff @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            reg_A <= '0;
            reg_Q <= '0;
            reg_M <= '0;
            count <= '0;
            busy <= 1'b0;
            done <= 1'b0;
            sign_dividend <= 1'b0;
            sign_divisor <= 1'b0;
            final_quotient <= '0;
            final_remainder <= '0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        reg_Q <= abs_dividend;
                        reg_M <= abs_divisor;
                        reg_A <= '0;
                        count <= XLEN;
                        sign_dividend <= is_signed && dividend[XLEN-1];
                        sign_divisor <= is_signed && divisor[XLEN-1];
                        busy <= 1'b1;
                        state <= COMPUTE;
                    end
                end
                
                COMPUTE: begin
                    reg_A <= alu_out;
                    reg_Q <= {reg_Q[XLEN-2:0], ~alu_out[XLEN]};
                    count <= count - 1;
                    if (count == 1) state <= RESTORE;
                end

                RESTORE: begin
                    if (reg_A[XLEN]) begin
                        reg_A <= reg_A + {1'b0, reg_M};
                    end
                    state <= DONE;
                end

                DONE: begin
                    // Calculate final results
                    logic sign_result;
                    logic sign_remainder;
                    logic [XLEN-1:0] quotient_abs;
                    logic [XLEN-1:0] remainder_abs;
                    
                    sign_result = sign_dividend ^ sign_divisor;
                    sign_remainder = sign_dividend;
                    quotient_abs = reg_Q;
                    remainder_abs = reg_A[XLEN-1:0];
                    
                    final_quotient <= (sign_result && quotient_abs != 0) ? -quotient_abs : quotient_abs;
                    final_remainder <= (sign_remainder && remainder_abs != 0) ? -remainder_abs : remainder_abs;
                    
                    busy <= 1'b0;
                    done <= 1'b1;
                    state <= IDLE;
                end
            endcase
        end
    end

    // Select output based on operation type
    assign result = is_rem ? final_remainder : final_quotient;
    assign remainder_out = final_remainder;

endmodule