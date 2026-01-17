import riscv_pkg::*;

module divider (
    input logic clk,
    input logic reset,
    input logic start,
    input logic is_signed, // 1 = signed, 0 = unsigned
    input logic is_rem, // 1 = remainder, 0 = quotient
    input logic [XLEN-1:0] dividend,
    input logic [XLEN-1:0] divisor,
    output logic [XLEN-1:0] result,
    output logic done,
    output logic busy
);
    timeunit 1ns;
    timeprecision 1ps;

    typedef enum logic [1:0] {
        IDLE,
        COMPUTE,
        DONE_STATE
    } state_e;
    
    state_e state, next_state;
    
    // Division registers
    logic [XLEN-1:0] quotient, next_quotient;
    logic [XLEN:0] remainder, next_remainder;  // 33 bits for subtraction
    logic [XLEN-1:0] divisor_reg, next_divisor_reg;
    logic [5:0] count, next_count;
    logic dividend_sign, divisor_sign;
    logic result_sign_div, result_sign_rem;
    logic [XLEN-1:0] dividend_abs, divisor_abs;
    

    assign dividend_sign = is_signed && dividend[31];
    assign divisor_sign = is_signed && divisor[31];
    assign result_sign_div = dividend_sign ^ divisor_sign;
    assign result_sign_rem = dividend_sign;    
    assign dividend_abs = dividend_sign ? (~dividend + 1) : dividend;
    assign divisor_abs = divisor_sign ? (~divisor + 1) : divisor;

    always_ff @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            quotient <= '0;
            remainder <= '0;
            divisor_reg <= '0;
            count <= '0;
        end else begin
            state <= next_state;
            quotient <= next_quotient;
            remainder <= next_remainder;
            divisor_reg <= next_divisor_reg;
            count <= next_count;
        end
    end

    always_comb begin
        next_state = state;
        next_quotient = quotient;
        next_remainder = remainder;
        next_divisor_reg = divisor_reg;
        next_count = count;
        
        case (state)
            IDLE: begin
                if (start) begin
                    next_quotient = '0;
                    next_remainder = {1'b0, dividend_abs};
                    next_divisor_reg = divisor_abs;
                    next_count = 0;
                    next_state = COMPUTE;
                end
            end
            
            COMPUTE: begin // Non-restoring division
                logic [XLEN:0] sub_result; 
                sub_result = remainder - {1'b0, divisor_reg};
                
                if (sub_result[XLEN] == 0) begin // remainder >= divisor (passed)
                    next_remainder = sub_result << 1;
                    next_quotient = {quotient[XLEN-2:0], 1'b1};
                end else begin // remainder < divisor ( failed)
                    next_remainder = remainder << 1;
                    next_quotient = {quotient[XLEN-2:0], 1'b0};
                end
                
                next_count = count + 1;
                
                if (count == 31) begin
                    next_state = DONE_STATE;
                end
            end
            
            DONE_STATE: begin
                next_state = IDLE;
            end
        endcase
    end

    always_comb begin
        done = (state == DONE_STATE);
        busy = (state == COMPUTE);
        
        if (divisor == 0) begin
            if (is_rem) begin
                result = dividend;  // REM (return dividend)
            end else begin
                result = 32'hFFFFFFFF;  // DIV: return -1
            end
        end else if (is_signed && dividend == 32'h80000000 && divisor == 32'hFFFFFFFF) begin
            if (is_rem) begin
                result = 0;
            end else begin
                result = 32'h80000000;
            end
        end else if (state == DONE_STATE) begin
            if (is_rem) begin
                logic [XLEN-1:0] rem_unsigned;
                rem_unsigned = remainder[XLEN:1];  // Shift right by 1
                result = result_sign_rem ? (~rem_unsigned + 1) : rem_unsigned;
            end else begin
                result = result_sign_div ? (~quotient + 1) : quotient;
            end
        end else begin
            result = '0;
        end
    end

endmodule