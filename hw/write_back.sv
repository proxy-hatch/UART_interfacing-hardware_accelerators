//(C) 2017 Eric Matthews, Lesley Shannon.  All rights reserved.
import riscv_config::*;
import riscv_types::*;
    
module write_back(
        input logic clk,
        input logic rst,
        
        input logic inorder,
        unit_writeback_interface.writeback unit_wb[NUM_WB_UNITS-1:0],
        register_file_writeback_interface.writeback rf_wb,
        instruction_queue_interface.wb iq,
        id_generator_interface.wb id_gen,
        output logic instruction_complete
        );
        
    logic done [NUM_WB_UNITS-1:0];
    logic early_done [NUM_WB_UNITS-1:0];
    
    logic accepted [NUM_WB_UNITS-1:0];
    logic [XLEN-1:0] rd [NUM_WB_UNITS-1:0];


        
        
    //logic inorder;
    logic not_in_queue;
    logic [4:0] rd_addr, rd_addr_r;
    logic [WB_UNITS_WIDTH-1:0] unit_id, unit_id_r;
    logic [$clog2(INSTRUCTION_QUEUE_DEPTH)-1:0] iq_index, iq_index_corrected, iq_index_r;
    instruction_id_t issue_id, issue_id_r;
        
        
    genvar i;
    generate
    for (i=0; i< NUM_WB_UNITS; i++) begin : interface_to_array_g
        assign done[i] = unit_wb[i].done;
        assign early_done[i] = unit_wb[i].early_done;
        assign rd[i] = unit_wb[i].rd;
        assign unit_wb[i].accepted = accepted[i];
    end
    endgenerate 
   // assign inorder = 0;
    
    always_comb begin
        //queue input
        not_in_queue = 1;
        unit_id = iq.data_in.unit_id;
        issue_id = iq.data_in.id;
        rd_addr = iq.data_in.rd_addr;
        iq_index = 0;
                
        //queue outputs
        for (int i=0; i<INSTRUCTION_QUEUE_DEPTH; i=i+1) begin
            if ( (iq.valid[i] && ~iq.pop[i]) //only consider valid entries and not the one completing this cycle
                    && (inorder || (~inorder && early_done[iq.data_out[i].unit_id]))) begin //if inorder set find oldest valid instruction, otherwise find oldest instruction that is done
                not_in_queue = 0;
                unit_id =  iq.data_out[i].unit_id;
                issue_id = iq.data_out[i].id;
                rd_addr = iq.data_out[i].rd_addr;
                iq_index = i;
            end
        end
    end
    
    always_ff @(posedge clk) begin
        if (rst)
            instruction_complete <= 0;
        else
            instruction_complete <= early_done[unit_id];
    end        
    
    assign iq_index_corrected = (~not_in_queue & iq.shift_pop[iq_index]) ? iq_index + 1: iq_index;
    
    always_ff @(posedge clk) begin
        iq_index_r <= iq_index_corrected;
        unit_id_r <= unit_id;
        issue_id_r <= issue_id;
        rd_addr_r <= rd_addr;
    end        
    
    //assign instruction_complete = unit_wb.done[unit_id];//iq.data_out[iq_index].valid & unit_wb.done[unit_id];
    
    assign rf_wb.rd_addr =  rd_addr_r;
    assign rf_wb.id =  issue_id_r;
    
    assign rf_wb.rd_data = rd[unit_id_r];
    assign rf_wb.valid_write = instruction_complete;
    
    assign rf_wb.rd_addr_early =  rd_addr;
    assign rf_wb.id_early =  issue_id;
    assign rf_wb.valid_write_early = early_done[unit_id];
    
    //genvar i;
    generate
        for (i=0; i<INSTRUCTION_QUEUE_DEPTH; i=i+1) begin : iq_pop
            always_ff @(posedge clk) begin
                if (rst)
                    iq.pop[i]  <= 0;
                else
                    iq.pop[i] <= early_done[unit_id] && (iq_index_corrected == i);
            end
        end
    endgenerate
    
    
    generate
        for (i=0; i<NUM_WB_UNITS; i=i+1) begin : wb_mux
            always_ff @(posedge clk) begin
                if (rst)
                    accepted[i] <= 0;
                else
                    accepted[i] <= early_done[i] && (unit_id == i);
            end
        end
    endgenerate
    
    //ID generator signals
    assign id_gen.complete = instruction_complete;
    assign id_gen.complete_id = issue_id_r;
endmodule
