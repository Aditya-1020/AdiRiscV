import riscv_pkg::*;

module tb_decoder;

    timeunit 1ns;
    timeprecision 1ps;

    logic [XLEN-1:0] instruction;
    ctrl_signals_t ctrl;

    decoder dut (
        .instruction(instruction),
        .ctrl(ctrl)
    );


    task automatic test_R_TYPE();

    endtask
    

    initial begin
        $dumpfile("decoder.vcd");
        $dumpvars(0, tb_decoder);


    end

endmodule