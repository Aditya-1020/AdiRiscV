import riscv_pkg::*;

module if_stage (
    input logic clk,
    input logic reset,
    
    // from hazard unit
    input logic pc_stall,
    
    // branch control form ex
    input logic branch_taken,
    input logic [XLEN-1:0] branch_target,

    // branch rediction
    input logic btb_update_en;
    input logic [XLEN-1:0] btb_pc_update;
    input logic [XLEN-1:0] btb_target_actual;
    input logic btb_is_branch_or_jmp;

    output if_id_reg_t if_id_out
);
    timeunit 1ns; timeprecision 1ps;

    localparam logic [4:0] RA_REG = 5'd1; // x1 (ra)
    localparam logic [4:0] T0_REG = 5'd5; // x5 (t0)

    logic [XLEN-1:0] pc, pc_plus4;
    logic [XLEN-1:0] instruction;
    logic [WORD_ADDR_WIDTH-1:0] imem_addr;
    logic pc_en;

    // prediction
    logic predict_taken;
    logic [XLEN-1:0] predict_target;

    // Ras
    logic is_call, is_return;
    logic ras_valid;
    logic [XLEN-1:0] ras_predicted_target;

    // btb
    logic btb_hit;
    logic [XLEN-1:0] btb_target_predicted;

    assign pc_en = 1'b1; // always 1 unless stalled

    pc pc_inst (
        .clk(clk),
        .reset(reset),
        .pc_en(pc_en),
        .pc_stall(pc_stall),
        .branch_taken(branch_taken),
        .branch_target(branch_target),
        .predict_taken(predict_taken),
        .predict_target(predict_target),
        .pc(pc),
        .pc_plus4(pc_plus4)
    );

    // imem
    // convert byte address to word address
    assign imem_addr = pc[WORD_ADDR_WIDTH+1:2];

    imem imem_inst (
        .clk(clk),
        .address(imem_addr),
        .instruction(instruction)
    );


    // detect calls/returns
    logic [REG_ADDR_WIDTH-1:0] rd, rs1;
    opcode_e opcode;

    assign rd = instruction[11:7];
    assign rs1 = instruction[19:15];
    assign opcode = opcode_e'(instruction[6:0]);

    logic is_jalr;
    assign is_jalr = (opcode == OP_JALR);
    
    // call jalr/jalr with link reg as dest
    assign is_call = (opcode == OP_JAL || is_jalr)  && (rd == RA_REG || rd == T0_REG);
    
    // return jalr with link reg as src, x0 as dest
    assign is_return = is_jalr && (rs1 == RA_REG || rs1 == T0_REG) && (rd == 5'd0);

    ras ras_inst (
        .clk(clk),
        .reset(reset),
        .push(is_call),
        .return_addr(pc_plus4),
        .pop(is_return),
        .predicted_return(ras_predicted_target),
        .valid(ras_valid)
    );

    // btb
    btb btb_inst (
        .clk(clk),
        .reset(reset),
        .pc_lookup(pc),
        .lookup_en(1'b1), // always en
        .update_en(btb_update_en),
        .pc_update(btb_pc_update),
        .target_actual(btb_target_actual),
        .is_branch_or_jmp(btb_is_branch_or_jmp),
        .hit(btb_hit),
        .target_predicted(btb_target_predicted)
    );

    // Prediction
    // Ras > BTB > Sequential

    always_comb begin
        if (is_return && ras_valid) begin // ras
            predict_taken = 1'b1;
            predict_target = ras_predicted_target;
        end else if (btb_hit) begin // btb
            predict_taken = 1'b1;
            predict_target = btb_target_actual;
        end else begin // seq
            predict_taken = 1'b0;
            predict_target = pc_plus4;
        end
    end


    // pack outputs
    always_comb begin
        if_id_out.pc = pc;instr_fetch
        if_id_out.instruction = instruction;
        if_id_out.pc_plus4 = pc_plus4;
        if_id_out.valid_if_id = 1'b1; // valid until flush activated
    end

endmodule