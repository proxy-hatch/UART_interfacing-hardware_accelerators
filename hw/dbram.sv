//(C) 2017 Eric Matthews, Lesley Shannon.  All rights reserved.
import riscv_config::*;
import riscv_types::*;

module dbram(
        input logic clk,
        input logic rst,
        
        input data_access_shared_inputs_t ls_inputs,
        ls_sub_unit_interface.sub_unit ls,
        output logic[31:0] data_out,
        
        bram_interface.user data_bram
        );

    assign ls.ready = ~ ls.data_valid | ( ls.data_valid & ls.ack);
    
    assign data_bram.addr = ls_inputs.addr[31:2];
    assign data_bram.en = ls.new_request;
    assign data_bram.be = ls_inputs.be;
    assign data_bram.data_in = ls_inputs.data_in;
    assign data_out = data_bram.data_out;
    
    always_ff @ (posedge clk) begin
        if (rst) 
            ls.data_valid <= 0;
        else if (ls.new_request & ls_inputs.load) 
            ls.data_valid <= 1;
        else if (ls.ack) 
            ls.data_valid <= 0;
    end
        
    
endmodule
                    
