import riscv_pkg::*;

module ras (
    input logic clk,
    input logic reset,
    
    input logic push,
    input logic [XLEN-1:0] return_addr,
    input logic pop,

    output logic [XLEN-1:0] predicted_return,
    output logic valid
);
    timeunit 1ns; timeprecision 1ps;

    typedef enum logic [1:0] {
        DEFAULT = 2'b00,
        PUSH = 2'b10,
        POP = 2'b01,
        PUSH_AND_POP = 2'b11,
    } stack_op_t;

    stack_op_t op;
    assign op = {push, pop};

    logic [XLEN-1:0] stack [RAS_SIZE-1:0];
    logic [RAS_PTR_WIDTH-1:0] tos; // top of stack
    logic [RAS_PTR_WIDTH:0] count; // no of entries (extra bit for full detection)

    logic pop_en, push_en;
    assign push_en = count < RAS_SIZE;
    assign pop_en = count > 0;


    assign valid = (count != 0);
    assign predicted_return = valid ? stack[tos] : '0;

    always_ff @(posedge clk) begin
        if (reset) begin
            tos <= '0;
            count <= '0;
        end else begin
            case (op)
                PUSH: begin // push only
                   tos <= (tos == RAS_SIZE-1) ? 0 : tos + 1;
                   stack[tos + 1] <= return_addr;
                   count <= push_en ? count + 1 : count; // inc if not full
                end

                POP: begin
                   tos <= pop_en ? (tos == 0 ? RAS_SIZE-1 : tos - 1) : tos;
                   count <= pop_en ? count  - 1 : count;  
                end

                PUSH_AND_POP: begin
                    stack[tos] <= return_addr; // replace top
                end
                default: begin
                    // do nothing 2'b00
                end
            endcase
        end
    end
    
endmodule