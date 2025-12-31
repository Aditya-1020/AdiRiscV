`timescale 1ps/1ps
`default_nettype none
`include "rtl/isa.vh"

module datapath (
    input wire clk,
    input wire reset,
    input wire branch_id, MemRead_id, MemToReg_id,
    input wire [3:0] ALU_op_id,
    input wire MemWrite_id, ALUSrc_id,
    input wire RegWrite_id, is_jal_id, is_jalr_id,
    input wire is_branch_id, is_jump_id,

    output wire [`XLEN-1:0] pc_if_debug,
    output wire [`XLEN-1:0] instruction_if_debug,
    output wire [`XLEN-1:0] pc_id_debug, instruction_id_debug,
    output wire branch_mispredict,
    output wire icache_stall
);

    // if
    wire [`XLEN-1:0] pc_if, pc_next_if, pc_plus4_if, instruction_if;
    wire btb_hit, prediction_if, ras_valid;
    wire [`XLEN-1:0] btb_target_if, predicted_pc_if, ras_top_addr;
    wire [1:0] predict_strength_if;
    wire [`RAS_PTR_WIDTH-1:0] ras_ptr;

    // id
    wire [`XLEN-1:0] pc_id, instruction_id, rs1_data_id, rs2_data_id, immediate_id, predicted_target_id;
    wire [4:0] rs1_id, rs2_id, rd_id;
    wire [2:0] funct3_id;
    wire [6:0] opcode_id;
    wire instr_30_id, prediction_id;

    //ex
    wire [`XLEN-1:0] pc_ex, rs1_data_ex, rs2_data_ex, immediate_ex, predicted_target_ex, pc_plus4_ex;
    wire [4:0] rs1_addr_ex, rs2_addr_ex, rd_ex;
    wire [2:0] funct3_ex;
    wire [6:0] opcode_ex;
    wire instr_30_ex, RegWrite_ex, MemToReg_ex, MemWrite_ex, MemRead_ex, ALUSrc_ex, branch_ex, prediction_ex;
    wire is_jal_ex, is_jalr_ex, is_branch_ex;
    wire [3:0] ALU_op_ex;

    wire [`XLEN-1:0] alu_in_a, alu_in_b, alu_result_ex, forwarded_rs1_ex, forwarded_rs2_ex, branch_target_ex, actual_next_pc_ex;
    wire [`XLEN-1:0] ex_result;  // Result to write back (either ALU result or PC+4)
    wire alu_zero_ex, branch_taken_ex;
    wire [1:0] forward_a, forward_b;

    // mem
    wire [`XLEN-1:0] alu_result_mem, rs2_data_mem, mem_read_data;
    wire [4:0] rd_mem;
    wire [2:0] funct3_mem;
    wire RegWrite_mem, MemToReg_mem, MemWrite_mem, MemRead_mem;
    reg [3:0] write_enable_mem;
    wire [1:0] load_type_mem;

    // wb
    wire [`XLEN-1:0] mem_data_wb, alu_result_wb, write_back_data;
    wire [4:0] rd_wb;
    wire RegWrite_wb, MemToReg_wb;

    //hazrd
    wire stall, flush_if, flush_id, flush_ex, control_hazard, load_use_stall;

    assign opcode_id = instruction_id[6:0];
    assign rs1_id = instruction_id[19:15];
    assign rs2_id = instruction_id[24:20];
    assign rd_id = instruction_id[11:7];
    assign funct3_id = instruction_id[14:12];
    assign instr_30_id = instruction_id[30];

    assign branch_mispredict = (branch_ex && (branch_taken_ex != prediction_ex)) || (is_jal_ex || is_jalr_ex);
    
    assign actual_next_pc_ex = is_jalr_ex ? ((forwarded_rs1_ex + immediate_ex) & ~32'h1) : (branch_taken_ex || is_jal_ex) ? branch_target_ex : (pc_ex + 4);

    assign control_hazard = branch_mispredict;
    assign flush_if = control_hazard;
    assign flush_id = control_hazard;
    assign flush_ex = 1'b0;

    // NO CACHE - direct instruction memory access
    assign icache_stall = 1'b0;  // Never stall
    assign stall = load_use_stall;

    wire use_ras_prediction = (opcode_id == `OP_J_JALR) && (rs1_id == 5'd1 || rs1_id == 5'd5) && ras_valid;
    assign predicted_pc_if = use_ras_prediction ? ras_top_addr : (btb_hit && prediction_if) ? btb_target_if : pc_plus4_if;
    assign pc_next_if = control_hazard ? actual_next_pc_ex : predicted_pc_if;

    pc pc_inst (
        .clk(clk),
        .reset(reset),
        // .pc_next(stall ? pc_if : pc_next_if),
        .pc_en(~stall),
        .pc_next(pc_next_if),
        .pc(pc_if)
    );
    
    pc_plus4 pc_plus4_inst (
        .pc_in(pc_if),
        .pc_plus4(pc_plus4_if)
    );

    btb btb_inst (
        .clk(clk),
        .reset(reset),
        .pc_if(pc_if),
        .lookup_enable(!stall),
        .update_enable(branch_ex || is_jal_ex || is_jalr_ex),
        .pc_update(pc_ex),
        .target_update(actual_next_pc_ex),
        .is_branch_or_jump(branch_ex || is_jal_ex || is_jalr_ex),
        .hit_valid(btb_hit),
        .target_predict(btb_target_if),
        .pc_hit()
    );

    branch_predictor bp_inst (
        .clk(clk),
        .reset(reset),
        .pc_if(pc_if),
        .predict_enable(!stall),
        .update_enable(branch_ex),
        .pc_update(pc_ex),
        .branch_taken(branch_taken_ex),
        .is_branch(is_branch_ex),
        .prediction(prediction_if),
        .predict_strength(predict_strength_if)
    );

    ras ras_inst (
        .clk(clk),
        .reset(reset),
        .flush(control_hazard),
        .push_en(is_jal_ex || is_jalr_ex),
        .return_addresss(pc_ex + 4),
        .opcode(opcode_ex),
        .rd(rd_ex),
        .pop_en(is_jalr_ex),
        .rs1(rs1_addr_ex),
        .top_stack_address(ras_top_addr),
        .valid_ras(ras_valid),
        .stack_ptr_out(ras_ptr)
    );

    instruction_mem imem_inst (
        .clk(clk),
        .reset(reset),
        .address(pc_if[11:2]),
        .instruction(instruction_if)
    );

    IF_ID_reg if_id_reg_inst (
        .clk(clk),
        .reset(reset),
        .stall(stall),
        .flush(flush_if),
        .pc_in(pc_if),
        .instruction_in(instruction_if),
        .prediction_in(prediction_if),
        .predicted_target_in(predicted_pc_if),
        .pc_out(pc_id),
        .instruction_out(instruction_id),
        .prediction_out(prediction_id),
        .predicted_target_out(predicted_target_id)
    );

    regfile register_inst (
        .clk(clk),
        .reset(reset),
        .rs1_addr(rs1_id),
        .rs2_addr(rs2_id),
        .rd(rd_wb),
        .write_data(write_back_data),
        .wr_en(RegWrite_wb),
        .rs1_data(rs1_data_id),
        .rs2_data(rs2_data_id)
    );

    imm_gen imm_gen_inst (
        .instruction(instruction_id),
        .immediate(immediate_id)
    );

    hazard_unit hazard_unit_inst (
        .rs1_id_in(rs1_id),
        .rs2_id_in(rs2_id),
        .rd_ex_in(rd_ex),
        .MemRead_in(MemRead_ex),
        .branch_in(branch_ex),
        .jump_in(is_jal_ex | is_jalr_ex),
        .stall(load_use_stall),
        .flush_ex(flush_ex)
    );

    wire [`XLEN-1:0] pc_plus4_id = pc_id + 4;

    ID_EX_reg id_ex_reg_inst (
        .clk(clk),
        .reset(reset),
        .flush(flush_id),
        .stall(1'b0),
        .RegWrite_in(stall ? 1'b0 : RegWrite_id),
        .MemToReg_in(stall ? 1'b0 : MemToReg_id),
        .MemWrite_in(stall ? 1'b0 : MemWrite_id),
        .MemRead_in(stall ? 1'b0 : MemRead_id),
        .ALUSrc_in(ALUSrc_id),
        .branch_in(stall ? 1'b0 : branch_id),
        .ALU_op_in(ALU_op_id),
        .is_jal_in(is_jal_id),
        .is_jalr_in(is_jalr_id),
        .is_branch_in(is_branch_id),
        .pc_in(pc_id),
        .rs1_data_in(rs1_data_id),
        .rs2_data_in(rs2_data_id),
        .immediate_in(immediate_id),
        .rs1_addr_in(rs1_id),
        .rs2_addr_in(rs2_id),
        .rd_addr_in(rd_id),
        .funct3_in(funct3_id),
        .opcode_in(opcode_id),
        .instr_30_in(instr_30_id),
        .prediction_in(prediction_id),
        .predicted_target_in(predicted_target_id),
        .RegWrite_out(RegWrite_ex),
        .MemToReg_out(MemToReg_ex),
        .MemWrite_out(MemWrite_ex),
        .MemRead_out(MemRead_ex),
        .ALUSrc_out(ALUSrc_ex),
        .branch_out(branch_ex),
        .ALU_op_out(ALU_op_ex),
        .is_jal_out(is_jal_ex),
        .is_jalr_out(is_jalr_ex),
        .is_branch_out(is_branch_ex),
        .pc_out(pc_ex),
        .rs1_data_out(rs1_data_ex),
        .rs2_data_out(rs2_data_ex),
        .immediate_out(immediate_ex),
        .rs1_addr_out(rs1_addr_ex),
        .rs2_addr_out(rs2_addr_ex),
        .rd_addr_out(rd_ex),
        .funct3_out(funct3_ex),
        .opcode_out(opcode_ex),
        .instr_30_out(instr_30_ex),
        .prediction_out(prediction_ex),
        .predicted_target_out(predicted_target_ex)
    );
    
    assign pc_plus4_ex = pc_ex + 4;
    
    forwarding_unit forwarding_unit_inst (
        .rs1_ex(rs1_addr_ex),
        .rs2_ex(rs2_addr_ex),
        .rd_mem(rd_mem),
        .rd_wb(rd_wb),
        .RegWrite_mem(RegWrite_mem),
        .RegWrite_wb(RegWrite_wb),
        .forward_a(forward_a),
        .forward_b(forward_b)
    );

    assign forwarded_rs1_ex = (forward_a == 2'b10) ? alu_result_mem : (forward_a == 2'b01) ? write_back_data : rs1_data_ex;
    assign forwarded_rs2_ex = (forward_b == 2'b10) ? alu_result_mem : (forward_b == 2'b01) ? write_back_data : rs2_data_ex;

    // assign alu_in_a = forwarded_rs1_ex;
    assign alu_in_a = (opcode_ex == `OP_U_AUIPC) ? pc_ex : forwarded_rs1_ex;
    assign alu_in_b = ALUSrc_ex ? immediate_ex : forwarded_rs2_ex;

    alu alu_inst (
        .a(alu_in_a),
        .b(alu_in_b),
        .ALUControl(ALU_op_ex),
        .zero(alu_zero_ex),
        .result(alu_result_ex)
    );

    assign ex_result = (is_jal_ex || is_jalr_ex) ? pc_plus4_ex : alu_result_ex;

    branch_control branch_control_inst (
        .funct3(funct3_ex),
        .opcode(opcode_ex),
        .alu_zero(alu_zero_ex),
        .rs1_data(forwarded_rs1_ex),
        .rs2_data(forwarded_rs2_ex),
        .branch_enable(branch_ex),
        .branch_taken(branch_taken_ex)
    );
    
    assign branch_target_ex = pc_ex + immediate_ex;

    EX_MEM_reg ex_mem_reg_inst (
        .clk(clk),
        .reset(reset),
        .stall(1'b0),
        .flush(flush_ex),
        .alu_result_in(ex_result),  // Use ex_result (PC+4 for JAL/JALR)
        .rs2_data_in(forwarded_rs2_ex),
        .RegWrite_in(RegWrite_ex),
        .MemToReg_in(MemToReg_ex),
        .MemWrite_in(MemWrite_ex),
        .MemRead_in(MemRead_ex),
        .branch_in(branch_ex),
        .rd_addr_in(rd_ex),
        .funct3_in(funct3_ex),
        .branch_target_in(branch_target_ex),
        .branch_taken_in(branch_taken_ex),
        .alu_result_out(alu_result_mem),
        .rs2_data_out(rs2_data_mem),
        .RegWrite_out(RegWrite_mem),
        .MemToReg_out(MemToReg_mem),
        .MemWrite_out(MemWrite_mem),
        .MemRead_out(MemRead_mem),
        .branch_out(),
        .rd_addr_out(rd_mem),
        .funct3_out(funct3_mem),
        .branch_target_out(),
        .branch_taken_out()
    );

    wire [1:0] store_addr_offset = alu_result_mem[1:0];

    always @(*) begin
        write_enable_mem = 4'b0000;
        if (MemWrite_mem) begin
            case (funct3_mem)
                `FUNCT3_SB: begin
                    case (store_addr_offset)
                        2'b00: write_enable_mem = 4'b0001;
                        2'b01: write_enable_mem = 4'b0010;
                        2'b10: write_enable_mem = 4'b0100;
                        2'b11: write_enable_mem = 4'b1000;
                    endcase
                end
                `FUNCT3_SH: begin
                    case (store_addr_offset[1])
                        1'b0: write_enable_mem = 4'b0011;
                        1'b1: write_enable_mem = 4'b1100;
                    endcase
                end
                `FUNCT3_SW: begin
                    write_enable_mem = 4'b1111;
                end
                default: write_enable_mem = 4'b0000;
            endcase
        end
    end


    reg [31:0] aligned_write_data;
    always @(*) begin
        case (funct3_mem)
            `FUNCT3_SB: begin
                case (store_addr_offset)
                    2'b00: aligned_write_data = {24'b0, rs2_data_mem[7:0]};
                    2'b01: aligned_write_data = {16'b0, rs2_data_mem[7:0], 8'b0};
                    2'b10: aligned_write_data = {8'b0, rs2_data_mem[7:0], 16'b0};
                    2'b11: aligned_write_data = {rs2_data_mem[7:0], 24'b0};
                    default: aligned_write_data = rs2_data_mem;
                endcase
            end
            `FUNCT3_SH: begin
                case (store_addr_offset[1])
                    1'b0: aligned_write_data = {16'b0, rs2_data_mem[15:0]};
                    1'b1: aligned_write_data = {rs2_data_mem[15:0], 16'b0};
                    default: aligned_write_data = rs2_data_mem;
                endcase
            end
            `FUNCT3_SW: aligned_write_data = rs2_data_mem;
            default: aligned_write_data = rs2_data_mem;
        endcase
    end
    
    assign load_type_mem = (funct3_mem == `FUNCT3_LB || funct3_mem == `FUNCT3_LBU) ? 2'b00 : (funct3_mem == `FUNCT3_LH || funct3_mem == `FUNCT3_LHU) ? 2'b01 : 2'b10;

    data_memory data_memory_inst (
        .clk(clk),
        .reset(reset),
        .address(alu_result_mem),
        .WriteData(aligned_write_data),
        .wr_en(write_enable_mem),
        .load_type(load_type_mem),
        .MemRead(MemRead_mem),
        .ReadData(mem_read_data)
    );

    MEM_WB_reg mem_wb_reg_inst (
        .clk(clk),
        .reset(reset),
        .stall(1'b0),
        .flush(1'b0),
        .mem_data_in(mem_read_data),
        .alu_result_in(alu_result_mem),
        .RegWrite_in(RegWrite_mem),
        .MemToReg_in(MemToReg_mem),
        .rd_addr_in(rd_mem),
        .mem_data_out(mem_data_wb),
        .alu_result_out(alu_result_wb),
        .RegWrite_out(RegWrite_wb),
        .MemToReg_out(MemToReg_wb),
        .rd_addr_out(rd_wb)
    );

    assign write_back_data = MemToReg_wb ? mem_data_wb : alu_result_wb;

    assign pc_if_debug = pc_if;
    assign instruction_if_debug = instruction_if;
    assign pc_id_debug = pc_id;
    assign instruction_id_debug = instruction_id;

endmodule