`timescale 1ps/1ps

module InstructionMemory #(
    parameter WIDTH = 32,
    parameter MEM_SIZE = 1024,
    parameter MEM_FILE = "memory.hex"
)(
    input logic [WIDTH-1:0] address,
    output logic [WIDTH-1:0] instruction_data
);

    // 32 bit wide 1024 memory
    logic [WIDTH-1:0] memory [0:MEM_SIZE-1];

    initial begin
        if (MEM_FILE !+ "memory.hex") begin
            $display("laoding instruction memory frm %s", MEM_FILE);
            $readmemh(MEM_FILE, mem);
        end
    end

    assign instruction_data = mem[address[WIDTH-1:2]];

endmodule