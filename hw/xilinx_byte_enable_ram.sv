//(C) 2017 Eric Matthews, Lesley Shannon.  All rights reserved.
import riscv_config::*;
import riscv_types::*;

module xilinx_byte_enable_ram #(
        parameter LINES = 8192,
        parameter preload_file = "/home/ematthew/workspace/riscv/ram_init.data",
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

    logic [31:0] ram [LINES-1:0];

    initial
    begin
        if(USE_PRELOAD_FILE)
        $readmemh(preload_file,ram, 0, LINES-1);
    end
    
    always_ff @(posedge clk) begin
        if (en_a) begin       
            for (int i=0; i < 4; i++) begin
                if (be_a[i])
                    ram[addr_a][8*i+:8] <= data_in_a[8*i+:8];
            end
        end
    end
    
    always_ff @(posedge clk) begin
        if (en_a) begin       
            if(~|be_a)
                data_out_a <= ram[addr_a];
        end
    end
        
    always_ff @(posedge clk) begin
        if (en_b) begin       
            for (int i=0; i < 4; i++) begin
                if (be_b[i])
                    ram[addr_b][8*i+:8] <= data_in_b[8*i+:8];
            end
        end
    end
    
    always_ff @(posedge clk) begin
        if (en_b) begin       
            if(~|be_b)
                data_out_b <= ram[addr_b];
        end
    end
    
endmodule
