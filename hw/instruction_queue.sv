//(C) 2017 Eric Matthews, Lesley Shannon.  All rights reserved.
import riscv_config::*;
import riscv_types::*;

//No protection on push to full queue or pop from empty
module instruction_queue
        (
        input logic clk,
        input logic rst, 
        input logic instruction_complete,
        instruction_queue_interface.queue iq
        );

    logic[$bits(instruction_queue_packet)-1:0] shift_reg[INSTRUCTION_QUEUE_DEPTH-1:0];
    //logic[INSTRUCTION_QUEUE_DEPTH-1:0] shift_pop;   
        
    //implementation
    assign iq.shift_pop[INSTRUCTION_QUEUE_DEPTH-1] = iq.pop[INSTRUCTION_QUEUE_DEPTH-1] | ~iq.valid[INSTRUCTION_QUEUE_DEPTH-1];
    always_comb begin
        for (int i=INSTRUCTION_QUEUE_DEPTH-2; i >=0; i--) begin
            iq.shift_pop[i] = iq.shift_pop[i+1] | (iq.pop[i] | ~iq.valid[i]);
        end
    end
        
    always_ff @ (posedge clk) begin
        if (rst)
            iq.valid[0] <= 0;        
        else if (iq.shift_pop[0])
            iq.valid[0] <= iq.new_issue;
    end
        
    always_ff @ (posedge clk) begin
        if (iq.shift_pop[0])
            shift_reg[0] <= iq.data_in;        
    end
        
    genvar i;
    generate
        for (i=1 ; i < INSTRUCTION_QUEUE_DEPTH; i++) begin : iq_valid_g
            always_ff @ (posedge clk) begin
                if (rst)
                    iq.valid[i] <= 0;
                else if (iq.shift_pop[i]) begin
                    iq.valid[i] <= iq.valid[i-1] & ~iq.pop[i-1];
                end
            end
        end
    endgenerate
                
    //Data portion
    assign iq.data_out[0] = shift_reg[0];
    generate
        for (i=1 ; i < INSTRUCTION_QUEUE_DEPTH; i++) begin : shift_reg_gen 
            assign iq.data_out[i] = shift_reg[i];
            always_ff @ (posedge clk) begin
                if (iq.shift_pop[i])
                    shift_reg[i] <= shift_reg[i-1];
            end            
        end
    endgenerate

endmodule


