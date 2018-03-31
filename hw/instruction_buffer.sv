//(C) 2017 Eric Matthews, Lesley Shannon.  All rights reserved.
import riscv_config::*;
import riscv_types::*;

//Circular buffer for instruction buffer.  Isolates push and pop signals so that critical paths can be separated
module instruction_buffer
        (
        input logic clk,
        input logic rst, 
        instruction_buffer_interface.buffer ib
        );

    //instruction_buffer_packet shift_reg[FETCH_BUFFER_DEPTH-1:0];
    logic[$bits(instruction_buffer_packet)-1:0] shift_reg[FETCH_BUFFER_DEPTH-1:0];
    logic[$bits(instruction_buffer_packet)-1:0] shift_reg_in;
    instruction_buffer_packet shift_reg_out;
    
    
    logic [$clog2(FETCH_BUFFER_DEPTH)-1:0] write_index;
    logic [$clog2(FETCH_BUFFER_DEPTH)-1:0] read_index;
    logic [$clog2(FETCH_BUFFER_DEPTH)-1:0] write_index_p1;
    logic [$clog2(FETCH_BUFFER_DEPTH)-1:0] write_index_p2;
    logic [$clog2(FETCH_BUFFER_DEPTH)-1:0] read_index_p1;
       
    logic[$clog2(FETCH_BUFFER_DEPTH):0] count;
    
    
    //implementation
    always_ff @ (posedge clk) begin
        if (rst)
            write_index <= 0;
        else if (ib.flush)
            write_index <= 0;
        else if (ib.push)
            write_index <= write_index_p1;
    end
    
    always_ff @ (posedge clk) begin
        if (rst)
            read_index <= 0;
        else if (ib.flush)
            read_index <= 0;
        else if (ib.pop)
            read_index <= read_index_p1;
    end
   
    assign write_index_p1 = write_index + 1;
    assign write_index_p2 = write_index + 2;
    
    assign read_index_p1 = read_index + 1;
    
    
    always_ff @ (posedge clk) begin
        if (rst | ib.flush)
            count <= 0;
        else if (ib.push & ~ib.pop)
            count <= count + 1;        
        else if (ib.pop && ~ib.push)
            count <= count - 1;
    end    
    
    always_ff @ (posedge clk) begin
        if (rst | ib.flush)
            ib.full <= 0;
        else if (ib.push && ~ib.pop && (count >= FETCH_BUFFER_DEPTH-1))
            ib.full <= 1;
        else if (ib.pop && ~ib.push && (count == FETCH_BUFFER_DEPTH))
            ib.full <= 0;
    end  
    
    always_ff @ (posedge clk) begin
        if (rst | ib.flush)
            ib.early_full <= 0;
        else if (ib.push && ~ib.pop && (count >= FETCH_BUFFER_DEPTH-2))
            ib.early_full <= 1;
        else if (ib.pop && ~ib.push && (count == FETCH_BUFFER_DEPTH-1))
            ib.early_full <= 0;
    end

     
    always_ff @ (posedge clk) begin
        if (rst | ib.flush)
            ib.valid <= '0;
        else if (ib.push)
            ib.valid <= '1;
        else if (ib.pop && read_index_p1 == write_index)
            ib.valid <= '0;
    end
       
    
    assign shift_reg_in = ib.data_in;
    
    always_ff @ (posedge clk) begin
        if (ib.push)
            shift_reg[write_index] <= shift_reg_in;
    end    
        
    assign ib.data_out = shift_reg[read_index];
   

endmodule


