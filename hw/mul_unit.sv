//(C) 2017 Eric Matthews, Lesley Shannon.  All rights reserved.
import riscv_config::*;
import riscv_types::*;
    
module mul_unit(
        input logic clk,
        input logic rst,
        func_unit_ex_interface.unit mul_ex,
        input mul_inputs_t mul_inputs,
        unit_writeback_interface.unit mul_wb//writeback_unit_interface_dummy.unit mul_wb//
        
        );
        
    parameter MUL_CYCLES = 2;
    parameter FIFO_DEPTH = 4;
    
    logic [$clog2(FIFO_DEPTH)-1:0] inflight_count;
    
    struct packed{
        logic [31:0] upper;
        logic [31:0] lower;
    } mul_result;

    logic [31:0] result;
    logic [1:0] mul_done_op;
    logic mul_done;
    
    fifo_interface #(.DATA_WIDTH(XLEN)) wb_fifo();
     

    always_ff @(posedge clk) begin         
        if (rst)
            inflight_count <= 0;
        else if ( mul_ex.new_request_dec & ~mul_wb.accepted)
            inflight_count <= inflight_count + 1;
        else if (mul_wb.accepted)
            inflight_count <= inflight_count - 1;
    end    
    
    //Multiply pathway fully pipelined
    always_ff @(posedge clk) begin
        if (rst)
            mul_ex.ready <= 1;
        else if (mul_ex.new_request_dec && ~mul_wb.accepted && inflight_count == (FIFO_DEPTH-1))
            mul_ex.ready <= 0;
        else if (mul_wb.accepted)
            mul_ex.ready <= 1;
    end    
    
    mul #(MUL_CYCLES) multiplier (.*, .A(mul_inputs.rs1), .B(mul_inputs.rs2),
            .P(mul_result), .new_request(mul_ex.new_request_dec), .op(mul_inputs.op),
            .done(mul_done), .completed_op(mul_done_op));

    always_comb begin
        case (mul_done_op)
            MUL_fn3[1:0] : result <= mul_result.lower;
            MULH_fn3[1:0] : result <= mul_result.upper;
            MULHSU_fn3[1:0] : result <= mul_result.upper;
            MULHU_fn3[1:0] : result <= mul_result.upper;
        endcase
    end
    
    /*********************************
     *  Output FIFO
     *********************************/
    non_muxed_on_output_buffer #(.DATA_WIDTH(XLEN), .FIFO_DEPTH(FIFO_DEPTH)) output_fifo (.fifo(wb_fifo), .*);
    
    assign wb_fifo.data_in = result;
    assign wb_fifo.push = mul_done;
    assign wb_fifo.pop = mul_wb.accepted;
    assign mul_wb.rd = wb_fifo.data_out;
    assign mul_wb.done = wb_fifo.valid;
    
    assign mul_wb.early_done = wb_fifo.early_valid;//mul_done | (mul_wb.done & ~mul_wb.accepted);
    /*********************************************/    

endmodule
