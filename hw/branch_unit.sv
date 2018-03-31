//(C) 2017 Eric Matthews, Lesley Shannon.  All rights reserved.
import riscv_config::*;
import riscv_types::*;

module branch_unit(
        input logic clk,
        input logic rst,
    
        func_unit_ex_interface.unit branch_ex,
        input branch_inputs_t branch_inputs, 
        branch_table_interface.branch_unit bt,
        unit_writeback_interface.unit branch_wb //writeback_unit_interface_dummy.unit branch_wb,//
    
        );
    
    logic result;
    logic equal;
    logic lessthan;
    
    logic equal_ex;
    logic lessthan_ex;    
    
    logic [XLEN:0] sub_result;
    logic [31:0] pc_offset;
    logic [2:0] fn3_ex;
    logic[31:0] rd_ex;  
    
    logic jump_ex;
    logic bcomp_ex;
    
    logic done;
        
        
    assign equal = (branch_inputs.rs1 == branch_inputs.rs2);
    assign sub_result = signed'({branch_inputs.rs1[XLEN-1] & branch_inputs.use_signed, branch_inputs.rs1}) - signed'({branch_inputs.rs2[XLEN-1] & branch_inputs.use_signed, branch_inputs.rs2});
    assign lessthan = sub_result[XLEN];
        
    always_comb begin
        unique case (fn3_ex) // <-- 010, 011 unused
            BEQ_fn3 : result = equal_ex;
            BNE_fn3 : result = ~equal_ex;
            BLT_fn3 : result = lessthan_ex;
            BGE_fn3 : result = ~lessthan_ex;
            BLTU_fn3 : result = lessthan_ex;
            BGEU_fn3 : result = ~lessthan_ex;
        endcase
    end
    
    assign  bt.branch_taken =  (bcomp_ex & result) | jump_ex;
    
    always_comb begin
        if (branch_inputs.jal)
            pc_offset = 32'(signed'({branch_inputs.jal_imm, 1'b0}));
        else if (branch_inputs.jalr)
            pc_offset = 32'(signed'(branch_inputs.jalr_imm));
        else
            pc_offset = 32'(signed'({branch_inputs.br_imm, 1'b0}));
    end
    
    assign bt.prediction_dec = branch_inputs.prediction;
    
    
    assign bt.branch_ex = branch_ex.new_request;
    always_ff @(posedge clk) begin
        if (branch_ex.new_request_dec) begin
            fn3_ex <= branch_inputs.fn3;
            equal_ex <= equal;
            lessthan_ex <= lessthan;
            bt.ex_pc <= branch_inputs.dec_pc;
            bcomp_ex <= branch_inputs.branch_compare;
            jump_ex <= branch_inputs.jal | branch_inputs.jalr;
            bt.jump_pc <= (branch_inputs.jalr ? branch_inputs.rs1 : branch_inputs.dec_pc) + signed'(pc_offset);
            bt.njump_pc <= branch_inputs.dec_pc + 4;
            //bt.prediction_dec <= branch_inputs.prediction;
            
        end
    end
    
    always_ff @(posedge clk) begin
        if (branch_ex.new_request_dec & (branch_inputs.jal | branch_inputs.jalr)) begin
            rd_ex <= branch_inputs.dec_pc + 4;
        end
    end
    
    
    /*********************************
     *  Output
     *********************************/
    assign branch_ex.ready = ~done | (done & branch_wb.accepted);

    assign branch_wb.rd =  rd_ex;
        
    always_ff @(posedge clk) begin
        if (rst) begin
            done <= 0;
        end else if (branch_ex.new_request_dec  & (branch_inputs.jal | branch_inputs.jalr)) begin
            done <= 1;
        end else if (branch_wb.accepted) begin
            done <= 0;
        end
    end
    
    assign branch_wb.done = done;
    assign branch_wb.early_done = (branch_ex.new_request_dec & (branch_inputs.jal | branch_inputs.jalr)) | (done & ~branch_wb.accepted);
    
    /*********************************************/        
    
endmodule
