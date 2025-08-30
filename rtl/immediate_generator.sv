`timescale 1ps/1ps
import isa_defs::*;

module immediate_generator (
    input logic [XLEN-1:0] instruction;
    input imm_gen_e ImmSrc,
    output logic [XLEN-1:0] immediate;
);
    
    always_comb begin
        case (ImmSrc)
            ITYPE: begin
                immediate = {{20{instruction[31]}}, instruction[31:20]};
            end
            STYPE: begin
                immediate = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
            end
            BTYPE: begin
                immediate = {{19{instruction[31]}}, instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0};
            end
            UTYPE: begin
                immediate = {instruction[31:12], 12'b0};
            end
            JTYPE: begin
                immediate = {{11{instruction[31]}}, instruction[31], instruction[19:12], instruction[20], instruction[30:21], 1'b0};
            end
            default: begin
                immediate = 32'bx;
            end
        endcase
    end

endmodule