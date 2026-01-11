import riscv_pkg::*;

module tb_pc_plus4;

    timeunit 1ns;
    timeprecision 1ps;

    initial begin
        assert(pc_plus4(32'h1000) == 32'h1004) else $error("FAILED 1");
        assert(pc_plus4(32'h0000) == 32'h0004) else $error("FAILED 2");
        assert(pc_plus4(32'hFFFFFFFC) == 32'h0) else $error("FAILED 3");
        $display("ALL PASSED");
        $finish;
    end
endmodule