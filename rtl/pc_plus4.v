`timescale 1ps/1ps
`default_nettype none
`include "rtl/isa.vh"

module pc_plus4 (
    input wire [`XLEN-1:0] pc_in,
    output wire [`XLEN-1:0] pc_plus4
);

    assign pc_plus4 = pc_in + 4;

endmodule