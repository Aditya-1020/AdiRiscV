`timescale 1ps/1ps
`default_nettype none
`include "rtl/isa.vh"

module forwarding_unit (
    input wire [4:0] rs1_ex, rs2_ex,
    input wire [4:0] rd_mem, rd_wb,
    input wire RegWrite_mem, RegWrite_wb,
    output reg [1:0] forward_a,
    output reg [1:0] forward_b
);

    always @(*) begin
        if (RegWrite_mem && (rd_mem != 5'b0) && (rd_mem == rs1_ex))
            forward_a = 2'b10;
        else if (RegWrite_wb && (rd_wb != 5'b0) && (rd_wb == rs1_ex))
            forward_a = 2'b01;
        else
            forward_a = 2'b00;

        if (RegWrite_mem && (rd_mem != 5'b0) && (rd_mem == rs2_ex))
            forward_b = 2'b10;
        else if (RegWrite_wb && (rd_wb != 5'b0) && (rd_wb == rs2_ex))
            forward_b = 2'b01;
        else
            forward_b = 2'b00;
    end

endmodule