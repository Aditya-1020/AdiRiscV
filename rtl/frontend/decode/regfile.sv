import riscv_pkg::*;

module regfile (
    input logic clk,
    input logic [4:0] rs1_addr, rs2_addr,
    input logic [4:0] rd,
    input logic [XLEN-1:0] write_data,
    input logic wr_en,
    output logic [XLEN-1:0] rs1_data,
    output logic [XLEN-1:0] rs2_data
);

    // logic [XLEN-1:0] registers [0:NUM_REGS-1];
    logic [XLEN-1:0] registers [NUM_REGS];


    always_ff @(posedge clk) begin
        if (wr_en && rd != 0)
            registers[rd] <= write_data;
    end

    always_comb begin
        rs1_data = (rs1_addr == 0) ? '0 : (wr_en && rd == rs1_addr) ? write_data : regfile[rs1_addr];
        rs2_data = (rs2_addr == 0) ? '0 : (wr_en && rd == rs2_addr) ? write_data : registers[rs2_addr];
    end

    /*
    integer i;
    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < NUM_REGS; i++) begin
                registers[i] <= 32'b0;
            end
        end else if (wr_en && rd != 5'b0) begin
            registers[rd] <= write_data;
        end
    end
    */

endmodule