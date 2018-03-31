//(C) 2017 Eric Matthews, Lesley Shannon.  All rights reserved.
import riscv_config::*;
import riscv_types::*;
    
module div_unit(
        input logic clk,
        input logic rst,
        func_unit_ex_interface.unit div_ex,
        input div_inputs_t div_inputs,
        unit_writeback_interface.unit div_wb//writeback_unit_interface_dummy.unit div_wb
        );
        
    logic div_complete;
    logic div_done;
    
    logic [31:0] quotient;
    logic [31:0] remainder;
    
    logic [31:0] result;
        
    logic signed_divop;
    logic quotient_signed;
    logic remainder_signed;
    logic dividend_signed;
    logic divisor_signed;
    
    logic div_abort;
    
    logic start;
    logic in_progress;
    
    logic [31:0] complementerA;
    logic [31:0] complementerB;
    logic negateA;
    logic negateB;
    logic [31:0] inA;
    logic [31:0] inB;
    
    logic [31:0] div_result_muxed;
    logic [31:0] div_result_sign_corrected;
    logic [31:0] wb_div_result;
    
    div_inputs_t stage1;
    
    fifo_interface #(.DATA_WIDTH($bits(div_inputs_t))) input_fifo();
    fifo_interface #(.DATA_WIDTH(XLEN)) wb_fifo();
    
    /*********************************
     *  Input FIFO
     *********************************/
    non_muxed_on_input_buffer #(.DATA_WIDTH($bits(div_inputs_t)), .FIFO_DEPTH(DIV_INPUT_BUFFER_DEPTH)) div_input_fifo (.fifo(input_fifo), .*);
    
    assign input_fifo.data_in = div_inputs;
    assign input_fifo.push = div_ex.new_request_dec;
    assign div_ex.ready = ~input_fifo.full;
    assign input_fifo.pop = div_done;
    assign stage1 = input_fifo.data_out;
    /*********************************************/
    
    assign start = input_fifo.valid & ( ~in_progress);
    //Abort prevents divider circuit from starting in the case that we are done in one cycle
    assign div_abort =  input_fifo.valid & (stage1.overflow  | stage1.div_zero | stage1.reuse_result);
    assign div_done = (div_complete | div_abort) & ~wb_fifo.full;
    
    //If more than one cycle set in_progress so that multiple start signals are not sent to the div unit.  Also in progress if an abort occurs but the output FIFO is full
    always_ff @(posedge clk) begin
        if (rst) begin
            in_progress <= 0;
        end else if (start & ((div_abort & wb_fifo.full) | (~div_abort))) begin
            in_progress <= 1;
        end else if (div_done) begin
            in_progress <= 0;
        end
    end   
    
    //Input and output sign determination
    assign signed_divop =  ~stage1.op[0];
    
    assign dividend_signed = signed_divop & stage1.rs1[31];
    assign divisor_signed = signed_divop & stage1.rs2[31];
    
    assign quotient_signed = signed_divop & (stage1.rs1[31] ^ stage1.rs2[31]);
    assign remainder_signed = signed_divop & (stage1.rs1[31]);    
    
    // Shared adders for sign conversion of inputs and outputs as they never occur on the same cycle
    //(div_complete | stage1.reuse_result) instead of div_done as other signals are not relevant for sign conversion
    //************
    assign inA = (div_complete | stage1.reuse_result) ? quotient : stage1.rs1;
    assign inB = (div_complete | stage1.reuse_result) ? remainder : stage1.rs2;
    
    assign negateA =  (div_complete | stage1.reuse_result) ? quotient_signed : dividend_signed;
    assign negateB =  (div_complete | stage1.reuse_result) ? remainder_signed : divisor_signed;
    
    assign complementerA = negateA ? -inA : inA;
    assign complementerB = negateB ? -inB : inB;
    //*************
            
    //Synthesis time algorithm choice for divider
    generate
        if(USE_VARIABLE_LATENCY_DIV)
            quickdiv #(XLEN) div (.*, .start(start & ~div_abort), .A(complementerA), .B(complementerB), .Q(quotient), .R(remainder), .complete(div_complete), .ack(div_done));
        else
            normdiv #(XLEN) div (.*, .start(start & ~div_abort), .A(complementerA), .B(complementerB), .Q(quotient), .R(remainder), .complete(div_complete), .ack(div_done));
    endgenerate
    
    //Output muxing   
    always_comb begin
        case (stage1.op)
            DIV_fn3[1:0] : div_result_muxed <= stage1.div_zero ? '1 : (stage1.overflow ? {1'b1, 31'b0} : complementerA);
            DIVU_fn3[1:0] : div_result_muxed <= stage1.div_zero ? '1 : complementerA;
            REM_fn3[1:0] : div_result_muxed <=stage1.div_zero ? stage1.rs1 : (stage1.overflow ? 0 : complementerB);
            REMU_fn3[1:0] : div_result_muxed <= stage1.div_zero ? stage1.rs1 : complementerB;
        endcase
    end
        
    /*********************************
     *  Output FIFO
     *********************************/
    non_muxed_on_output_buffer #(.DATA_WIDTH(XLEN), .FIFO_DEPTH(DIV_OUTPUT_BUFFER_DEPTH)) output_fifo (.fifo(wb_fifo), .*);
    
    assign wb_fifo.data_in = div_result_muxed;
    assign wb_fifo.push = div_done;
    assign wb_fifo.pop = div_wb.accepted;
    assign div_wb.rd = wb_fifo.data_out;
    assign div_wb.done = wb_fifo.valid;
    
    assign div_wb.early_done = wb_fifo.early_valid;//div_done | (div_wb.done & ~div_wb.accepted);
    
    /*********************************************/
    
endmodule
