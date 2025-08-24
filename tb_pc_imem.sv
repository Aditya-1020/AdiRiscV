module tb_pc_imem
    logic clk, reset;
    logic [31:0] pc, pc_next, instr;

    assign pc_next = pc + 4;

    PC pc_inst (
        .clk(clk),
        .reset(reset),
        .pc_next(pc_next),
        .pc(pc)
    );

    imem imem_inst (
        .clk(clk),
        .addr(pc),
        .instr(instr)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        reset = 1;
        #20;
        reset = 0;

        repeat(10) @(posedge clk); //  run for 10 cycles 

        $$display("Final pc : 0x%h", pc);
        $finish;
    end

    always @(posedge clk) begin
        if (!reset)
            $display("Time: %0t, Pc: 0x%h, Instr: 0x%h", $time, pc, instr);
    end

endmodule