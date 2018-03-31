//(C) 2017 Eric Matthews, Lesley Shannon.  All rights reserved.
import riscv_config::*;
import riscv_types::*;

/*
 * Shift register FIFO implementation with a conservative full signal.
 * Full is registered so a full FIFO cannot support a simultaneous push and pop operations
 *   - As the FIFO is full at this point throughput for this logic path is not affected 
 * Output register is a fixed register while the input is passed to all FIFO registers
 *   - Suitable for implementations where output data is on critical path compared to
 *      input data
 */
module non_muxed_on_output_buffer #(parameter DATA_WIDTH = 32, parameter FIFO_DEPTH = 2)
        (
        input logic clk,
        input logic rst, 
        fifo_interface.structure fifo
        );

    logic[DATA_WIDTH-1:0] shift_reg[FIFO_DEPTH-1:0];
    
    logic[$clog2(FIFO_DEPTH)-1:0] write_index;
    logic[$clog2(FIFO_DEPTH)-1:0] read_index;
    logic[$clog2(FIFO_DEPTH)-1:0] write_index_p1;
    logic[$clog2(FIFO_DEPTH)-1:0] write_index_p2;
    logic[$clog2(FIFO_DEPTH)-1:0] read_index_p1;   
    
    logic[$clog2(FIFO_DEPTH):0] count;
    logic more_than_one;    
    
    //implementation
    assign fifo.data_out = shift_reg[read_index];
    
    assign write_index_p1 = write_index + 1;
    assign read_index_p1 = read_index + 1;
    
    assign write_index_p2 = write_index + 2;
    
    always_ff @ (posedge clk) begin
        if (rst)
            write_index <= '0;
        else if (fifo.push)
            write_index <= write_index_p1;
    end
    
    always_ff @ (posedge clk) begin
        if (rst)
            read_index <= '0;
        else if (fifo.pop)
            read_index <= read_index_p1;
    end    
   
    always_ff @ (posedge clk) begin
        if (rst)
            fifo.early_full <= 0;
        else if (fifo.push && ~fifo.pop && (write_index_p2 == read_index))
            fifo.early_full <= 1;
        else if (fifo.pop)
            fifo.early_full <= 0;
    end    
    
    always_ff @ (posedge clk) begin
        if (rst)
            fifo.full <= 0;
        else if (fifo.push && ~fifo.pop && write_index_p1 == read_index)
            fifo.full <= 1;
        else if (fifo.pop)
            fifo.full <= 0;
    end
     
    always_ff @ (posedge clk) begin
        if (rst)
            fifo.valid <= 0;
        else if (fifo.push)
            fifo.valid <= 1;
        else if (fifo.pop && read_index_p1 == write_index) 
            fifo.valid <= 0;
    end
       
    always_ff @ (posedge clk) begin
        if (fifo.push)
            shift_reg[write_index] <= fifo.data_in;
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
    
    assign fifo.early_valid = fifo.push || ((more_than_one) || (fifo.valid && ~fifo.pop));    

endmodule


