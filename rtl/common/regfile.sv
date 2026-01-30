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
    timeunit 1ns; timeprecision 1ps;

    localparam REG_ZERO = 5'd0;

    // 32 reg x0 always 0
    (* ram_style = "distributed" *) logic [XLEN-1:0] registers [0:NUM_REGS-1]; 

    logic reg_write_en;
    assign reg_write_en = wr_en && (rd != REG_ZERO);

    always_ff @(posedge clk) begin
        if (reset) begin
            for (int i = 0; i < NUM_REGS; i++) begin
                registers[i] <= RESET_REG;
            end
        end else if (reg_write_en) begin
            registers[rd] <= write_data;
        end
    end

    logic [XLEN-1:0] rs1_data_raw, rs2_data_raw;

    always_comb begin
        // read from regfile
        rs1_data_raw = (rs1_addr == REG_ZERO) ? '0 : registers[rs1_addr];
        rs2_data_raw = (rs2_addr == REG_ZERO) ? '0 : registers[rs2_addr];

        // forward if writing to same reg
        rs1_data = (reg_write_en && (rd == rs1_addr)) ? write_data : rs1_data_raw;
        rs2_data = (reg_write_en && (rd == rs2_addr)) ? write_data : rs2_data_raw;
    end

endmodule