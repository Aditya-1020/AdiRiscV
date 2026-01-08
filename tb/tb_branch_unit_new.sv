import riscv_pkg::*;

module tb_branch_unit;

    timeunit 1ns;
    timeprecision 1ps;

    logic [XLEN-1:0] rs1_data, rs2_data;
    logic [XLEN-1:0] pc, imm;
    funct3_branch_e funct3;
    opcode_e opcode;
    logic branch_taken;
    logic [XLEN-1:0] branch_target;
    logic is_jump;

    int pass_count = 0;
    int fail_count = 0;

    branch_unit dut (
        .rs1_data(rs1_data),
        .rs2_data(rs2_data),
        .pc(pc),
        .imm(imm),
        .funct3(funct3),
        .opcode(opcode),
        .branch_taken(branch_taken),
        .branch_target(branch_target),
        .is_jump(is_jump)
    );


    // calculate expected
    function automatic logic reference_condition(
        input funct3_branch_e funct3,
        input logic [XLEN1-1:0] a, b
    );
        case (funct3)
            F3_BEQ: return (a == b);
            F3_BNE: return (a != b);
            F3_BLT: return (signed'(a) < signed'(b));
            F3_BGE: return (signed'(a) >= signed'(b));
            F3_BLTU: return (a < b);
            F3_BGEU: return (a >= b);
            default: return 1'b0;
        endcase
    endfunction


    function automatic logic [XLEN-1:0] reference_target(
        input opcode_e opcode,
        input logic [XLEN-1:0] pc, rs1, immediate
    );
        if (opcode == OP_JALR)
            return (rs1 + imm) & ~32'h1;
        else
            return pc + imm;
    endfunction

    function automatic logic reference_taken(
        input opcode_e opcode,
        input funct3_branch_e funct3,
        input logic [XLEN-1:0] rs1, rs2
    );
        if (opcode == OP_JAL || opcode == OP_JALR)
            return 1'b1;
        else if (opcode == OP_BRANCH)
            return reference_condition(funct3, rs1, rs2);
        else
            return 1'b0;
    endfunction

    task automatic test_case(
        input string name,
        input opcode_e opcode_tst,
        input funct3_branch_e funct3_tst,
        input logic [XLEN-1:0] rs1, rs2, pc_tst, imm_tst
    );
        logic expected_takeen;
        logic [XLEN-1:0] expected_target;
        logic expected_is_jump;

        opcode = opcode_tst;
        funct3 = funct3_tst;
        rs1_data = rs1;
        rs2_data = rs2;
        pc = pc_tst;
        imm = imm_tst;

        // expected calculation
        expected_takeen = reference_taken(opcode_tst, funct3_tst, rs1, rs2);
        expected_target = reference_target(opcode_tst, pc_tst, rs1, imm_tst);
        expected_is_jump = (opcode_tst == OP_JAL || opcode_tst == OP_JALR);
        #1;

        if (branch_taken !== expected_takeen ||
            branch_target !== expected_target || 
            is_jump !== expected_is_jump) begin
                
                $display("FAiLED: %s\nInput: opcode=%s funct3=%s, rs1=%0x(0x%h), rs2=%0d(0x%h), pc=0x%h, imm=%0d(0x%h)", 
                name, opcode_tst.name(), funct3_tst.name(), signed'(rs1), rs1, signed'(rs2), rs2, pc_tst, signed'(imm_tst), imm_tst)
                $display("\nExpcted: taken=%b, target=0x%h, is_jump=%b", expected_takeen, expected_target, expected_is_jump);
                $display("\nGOT: taken=%b, target=0x%h, isjump%b", branch_taken, branch_target, is_jump);
                fail_count++;
            end else begin
                $display("PASSED: %s", name);pass_count++;
            end
    endtask

    // random test task
    task automatic random_tests(input int num_tests);
        logic [XLEN-1:0] rand_rs1, rand_rs2, rand_pc, rand_imm;
        opcode_e rand_opcode;
        funct3_branch_e rand_funct3;
        int opcode_choice, funct3_choice;

        $display("$0d Random tests", num_tests);
            
        for (int i = 0; i < num_tests; i++) begin
            rand_rs1 = $urandom();
            rand_rs2 = $urandom();
            rand_pc = $urandom();
            rand_imm = $urandom();
            
            opcode_choice = $urandom_range(0, 2);
            case (opcode_choice)
                0: rand_opcode = OP_BRANCH;
                1: rand_opcode = OP_JAL;
                2: rand_opcode = OP_JALR;
            endcase

            funct3_choice = $urandom_range(0, 5);
            case (funct3_choice)
                0: rand_funct3 = F3_BEQ;
                1: rand_funct3 = F3_BNE;
                2: rand_funct3 = F3_BLT;
                3: rand_funct3 = F3_BGE;
                4: rand_funct3 = F3_BLTU;
                5: rand_funct3 = F3_BGEU;
            endcase

            test_case($sformatf("Random test %0d", i), rand_opcode, rand_funct3, rand_rs1, rand_rs2, rand_pc, rand_imm);
        end
    endtask

    initial begin
        $display("BRANCH UNIT TEST");

        // 
    end

endmodule