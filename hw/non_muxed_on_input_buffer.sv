//(C) 2017 Eric Matthews, Lesley Shannon.  All rights reserved.
import riscv_config::*;
import riscv_types::*;

//Min depth 4 for packing into LUT shift register
module non_muxed_on_input_buffer #(parameter DATA_WIDTH = 32, parameter FIFO_DEPTH = 4)
        (
        input logic clk,
        input logic rst, 
        fifo_interface.structure fifo
        );

    logic[DATA_WIDTH-1:0] shift_reg[FIFO_DEPTH-1:0];
    
    logic[$clog2(FIFO_DEPTH)-1:0] read_index;
    logic[$clog2(FIFO_DEPTH):0] count;
    logic more_than_one;
    
    //implementation
    assign fifo.data_out = shift_reg[read_index];
    
    always_ff @ (posedge clk) begin
        if (rst)
            read_index <= 0;
        else if (fifo.valid & fifo.push & ~fifo.pop)
            read_index <= read_index + 1;        
        else if (fifo.pop && ~fifo.push && (read_index !=0))
            read_index <= read_index - 1;
    end
    
    
    always_ff @ (posedge clk) begin
        if (rst)
            count <= 0;
        else if (fifo.push & ~fifo.pop)
            count <= count + 1;        
        else if (fifo.pop && ~fifo.push)
            count <= count - 1;
    end
    
    always_ff @ (posedge clk) begin
        if (rst)
            more_than_one <= 0;
        else if (count == 1 && fifo.push & ~fifo.pop )
            more_than_one <= 1;
        else if (count == 2 && ~fifo.push & fifo.pop )
            more_than_one <= 0;
    end    
    
    assign fifo.early_valid = fifo.push | ((more_than_one & fifo.pop) | (fifo.valid & ~fifo.pop));
    
    always_ff @ (posedge clk) begin
        if (rst)
            fifo.full <= 0;
        else if (fifo.push && ~fifo.pop && (count == (FIFO_DEPTH-1)))
            fifo.full <= 1;
        else if (fifo.pop)
            fifo.full <= 0;
    end
    
    always_ff @ (posedge clk) begin
        if (rst)
            fifo.early_full <= 0;
        else if (fifo.push && ~fifo.pop && (count == (FIFO_DEPTH-2)))
            fifo.early_full <= 1;
        else if (fifo.pop)
            fifo.early_full <= 0;
    end    
     
    always_ff @ (posedge clk) begin
        if (rst)
            fifo.valid <= 0;
        else if (fifo.push)
            fifo.valid <= 1;
        else if (fifo.pop && read_index == 0) 
            fifo.valid <= 0;
    end
    assign fifo.empty = ~fifo.valid;
    
    always_ff @ (posedge clk) begin
        if (fifo.push) begin
            shift_reg[0] <= fifo.data_in;
            for (int i = 0; i < FIFO_DEPTH-1; i = i + 1)
                shift_reg[i+1] <= shift_reg[i];
        end
    end

endmodule


