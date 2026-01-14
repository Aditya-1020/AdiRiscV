import riscv_pkg::*;

module riscv_single_cycle_core (
    input logic clk,
    input logic reset
);

    timeunit 1ns;
    timeprecision 1ps;

    // Signals

    // PC
    logic [XLEN-1:0] pc, pc_next;
    logic pc_en;

    // IMEM
    logic [WORD_ADDR_WIDTH-1:0] imem_addr;
    logic [XLEN-1:0] instruction;

    // Decode
    logic [4:0] rs1_addr, rs2_addr, rd_addr;
    logic [XLEN-1:0] immediate;
    ctrl_signals_t ctrl;

    // Regfile
    logic [XLEN-1:0] rs1_data, rs2_data;
    logic [XLEN-1:0] write_data;

    // ALU
    logic [XLEN-1:0] alu_a, alu_b;
    logic [XLEN-1:0] alu_result;
    logic alu_zero;

    // Branch unit
    logic branch_taken;
    logic [XLEN-1:0] branch_target;
    logic is_jump;
    funct3_branch_e funct3_branch;
    opcode_e opcode;

    // DMEM
    logic [XLEN-1:0] dmem_addr;
    logic [XLEN-1:0] dmem_wdata;
    logic [XLEN-1:0] dmem_rdata;

    // control
    logic [XLEN-1:0] pc_plus4;

    assign pc_plus4 = pc + 32'd4;

    // ID
    assign opcode = opcode_e'(instruction[6:0]);
    assign rd_addr = instruction[11:7];
    assign rs1_addr = instruction[19:15];
    assign rs2_addr = instruction[24:20];
    assign funct3_branch = funct3_branch_e'(instruction[14:12]);

    pc pc_inst (
        .clk(clk),
        .reset(reset),
        .pc_en(pc_en),
        .pc_next(pc_next),
        .pc(pc)
    );

    assign imem_addr = pc[WORD_ADDR_WIDTH+1:2]; // byte addr to word address

    imem imem_inst (
        .address(imem_addr),
        .instruction(instruction)
    );

    imm_gen imm_gen_inst (
        .instruction(instruction),
        .immediate(immediate)
    );

    decoder decoder_inst (
        .instruction(instruction),
        .ctrl(ctrl)
    );

    regfile regfile_inst (
        .clk(clk),
        .reset(reset),
        .rs1_addr(rs1_addr),
        .rs2_addr(rs2_addr),
        .rd(rd_addr),
        .write_data(write_data),
        .wr_en(ctrl.reg_write),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data)
    );

    always_comb begin
        if (opcode == OP_AUIPC) begin
            alu_a = pc;
        end else begin
            alu_a = rs1_data;
        end
    end

    assign alu_b = ctrl.alu_src ? immediate : rs2_data;

    alu alu_inst (
        .a(alu_a),
        .b(alu_b),
        .op(ctrl.alu_op),
        .zero(alu_zero),
        .result(alu_result)
    );

    branch_unit branch_unit_inst (
        .rs1_data(rs1_data),
        .rs2_data(rs2_data),
        .pc(pc),
        .imm(immediate),
        .funct3(funct3_branch),
        .opcode(opcode),
        .branch_taken(branch_taken),
        .branch_target(branch_target),
        .is_jump(is_jump)
    );


    assign dmem_addr = alu_result;
    assign dmem_wdata = rs2_data;

    dmem dmem_inst (
        .clk(clk),
        .addr(dmem_addr),
        .wdata(dmem_wdata),
        .wr_en(ctrl.mem_write),
        .rd_en(ctrl.mem_read),
        .mem_op(ctrl.mem_op),
        .rdata(dmem_rdata)
    );

    // WB

    always_comb begin
        if (is_jump) begin
            write_data = pc_plus4;
        end else if (ctrl.mem_to_reg) begin
            write_data = dmem_rdata;
        end else begin
            write_data = alu_result;
        end
    end


    always_comb begin
        if (branch_taken) begin
            pc_next = branch_target;
        end else begin
            pc_next = pc_plus4;
        end
    end

    assign pc_en = 1'b1; // always 1 in signle-cycle (no stalls)


endmodule