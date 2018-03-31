//(C) 2017 Eric Matthews, Lesley Shannon.  All rights reserved.
import riscv_config::*;
import riscv_types::*;

module byte_en_BRAM #(
        parameter LINES = 8192,
        parameter preload_file = "/data/ENSC350-riscv/dhrystone.raminit",
        parameter USE_PRELOAD_FILE = 0
        )
        (
        input logic clk,
        input logic[$clog2(LINES)-1:0] addr_a,
        input logic en_a,
        input logic[XLEN/8-1:0] be_a,
        input logic[XLEN-1:0] data_in_a,
        output logic[XLEN-1:0] data_out_a,
        
        input logic[$clog2(LINES)-1:0] addr_b,
        input logic en_b,
        input logic[XLEN/8-1:0] be_b,
        input logic[XLEN-1:0] data_in_b,
        output logic[XLEN-1:0] data_out_b
        );

    generate
        if(FPGA_VENDOR == "xilinx")
            xilinx_byte_enable_ram #(LINES, preload_file, USE_PRELOAD_FILE) ram_block (.*);
        else
            altera_byte_enable_ram #(LINES, preload_file, USE_PRELOAD_FILE) ram_block (.*);
    endgenerate    
    
endmodule
