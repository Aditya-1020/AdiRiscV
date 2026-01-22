import riscv_pkg::*;

module regfile (
    input logic clk,
    input logic reset,
    input logic [REG_ADDR_WIDTH-1:0] rs1_addr, rs2_addr,
    input logic [REG_ADDR_WIDTH-1:0] rd,
    input logic [XLEN-1:0] write_data,
    input logic wr_en,
    output logic [XLEN-1:0] rs1_data,
    output logic [XLEN-1:0] rs2_data
);

    timeunit 1ns;
    timeprecision 1ps;
    
    // logic [XLEN-1:0] registers [0:NUM_REGS-1];
    (* ram_style = "distributed" *) logic [XLEN-1:0] registers [1:NUM_REGS-1]; 

    always_ff @(posedge clk) begin
        if (reset) begin
            for (int i = 1; i < NUM_REGS; i++) begin
                registers[i] <= RESET_REG;
            end
        end
        else begin
            if (wr_en && (rd != '0)) begin
                registers[rd] <= write_data;
            end
        end
    end

    always_comb begin
        rs1_data = (rs1_addr == '0) ? '0 : (wr_en && rd == rs1_addr) ? write_data : registers[rs1_addr];
        rs2_data = (rs2_addr == '0) ? '0 : (wr_en && rd == rs2_addr) ? write_data : registers[rs2_addr];
    end

endmodule