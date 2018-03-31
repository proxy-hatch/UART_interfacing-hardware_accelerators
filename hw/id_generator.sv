//(C) 2017 Eric Matthews, Lesley Shannon.  All rights reserved.
import riscv_config::*;
import riscv_types::*;

module id_generator (
        input logic clk,
        input logic rst,
        
        id_generator_interface.generator id_gen
        );
  
    logic inuse [0:INSTRUCTION_QUEUE_DEPTH-1];
        
    always_ff @ (posedge clk) begin
			for (int i=0; i <INSTRUCTION_QUEUE_DEPTH; i=i+1) begin
        //foreach(inuse[i]) begin
            if(rst)
                inuse[i] <= 0;
            begin
                if(id_gen.advance && id_gen.issue_id == i)
                    inuse[i] <= 1;
                else if (id_gen.complete && id_gen.complete_id == i)
                    inuse[i] <= 0;
            end
        end
    end
    
    always_comb begin
        id_gen.issue_id = id_gen.complete_id;
			for (int i=0; i <INSTRUCTION_QUEUE_DEPTH; i=i+1) begin
        //foreach(inuse[i]) begin
            if(~inuse[i])
                id_gen.issue_id = i;
        end
    end
    
    always_comb begin
        id_gen.id_avaliable = id_gen.complete;
			for (int i=0; i <INSTRUCTION_QUEUE_DEPTH; i=i+1) begin
        //foreach(inuse[i]) begin
            if(~inuse[i])
                id_gen.id_avaliable = 1;
        end
        
    end    
    
endmodule


