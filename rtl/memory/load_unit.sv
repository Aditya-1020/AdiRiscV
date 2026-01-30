import riscv_pkg::*;

module load_unit (
    input logic [XLEN-1:0] addr,
    input logic [XLEN-1:0] mem_rdata_raw,
    input mem_op_e mem_op,
    output logic [XLEN-1:0] rdata_aligned
);
    timeunit 1ns; timeprecision 1ps;

    logic [1:0] byte_offset;
    assign byte_offset = addr[1:0];

    logic [BYTE_SIZE-1:0] byte_data;
    logic [HALF_WORD_SIZE-1:0] half_data;

    always_comb begin
        case (byte_offset)
            2'b00: byte_data = mem_rdata_raw[7:0];
            2'b01: byte_data = mem_rdata_raw[15:8];
            2'b10: byte_data = mem_rdata_raw[23:16];
            2'b11: byte_data = mem_rdata_raw[31:24];
            default: byte_data = 8'h00;
        endcase

        // half word select based on addr bit 1
        half_data = addr[1] ? mem_rdata_raw[31:16] : mem_rdata_raw[15:0];

        // Align and extend based on operation type
        case (mem_op)
            MEM_BYTE:   rdata_aligned = {{24{byte_data[7]}}, byte_data};
            MEM_BYTE_U: rdata_aligned = {{24{1'b0}}, byte_data};
            MEM_HALF:   rdata_aligned = {{16{half_data[15]}}, half_data};
            MEM_HALF_U: rdata_aligned = {{16{1'b0}}, half_data};
            MEM_WORD:   rdata_aligned = mem_rdata_raw;
            default:    rdata_aligned = 32'h00000000;
        endcase
    end
endmodule