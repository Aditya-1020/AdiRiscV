`timescale 1ps/1ps

// Program Counter
module PC #(parameter WIDTH = 32)(
    input  logic                clk,
    input  logic                reset,
    input  logic [WIDTH-1:0]    pc_in, // pc_next
    output logic [WIDTH-1:0]    pc_out // pc
);

    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            pc <= 32'h0;
        else
            pc <= pc_in;
    end

endmodule