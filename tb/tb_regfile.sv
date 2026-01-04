import riscv_pkg::*;

module tb_regfile;
    timeunit 1ns;
    timeprecision 1ps;

    logic clk,
    logic [4:0] rs1_addr, rs2_addr, rd;
    logic [XLEN-1:0] write_data;
    logic wr_en;
    logic [XLEN-1:0] rs1_data, rs2_data;


    int pass_count = 0;
    int fail_count = 0;
    int test_num = 0;

    regfile dut (
        .clk(clk),
        .rs1_addr(rs1_addr),
        .rs2_addr(rs2_addr),
        .rd(rd),
        .write_data(write_data),
        .wr_en(wr_en),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data)
    );

endmodule