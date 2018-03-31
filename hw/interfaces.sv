//(C) 2017 Eric Matthews, Lesley Shannon.  All rights reserved.
import riscv_config::*;
import riscv_types::*;

interface bram_interface;
    logic[29:0] addr;
    logic en;
    logic[XLEN/8-1:0] be;
    logic[XLEN-1:0] data_in;
    logic[XLEN-1:0] data_out;
    
    modport bram (input addr, en, be, data_in, output data_out);
    modport user (output addr, en, be, data_in, input data_out);
endinterface

interface branch_table_interface;
    logic[31:0] if_pc;
    logic[31:0] dec_pc;
    logic[31:0] ex_pc;
    logic [31:0] jump_pc;
    logic [31:0] njump_pc;
    
    logic[31:0] next_pc;
    
    logic next_pc_valid;
    
    logic branch_taken;
    logic branch_ex;
    logic prediction_dec;
    
    
    logic[31:0]  predicted_pc;
    logic prediction;
    logic use_prediction;
    logic flush;
    
    modport branch_table (input if_pc, dec_pc, ex_pc, next_pc, njump_pc, jump_pc, branch_taken, branch_ex, prediction_dec, next_pc_valid, output predicted_pc, prediction, use_prediction, flush);
    modport fetch (input predicted_pc, prediction, use_prediction, branch_taken, flush, njump_pc, jump_pc, output if_pc, next_pc, next_pc_valid);
    modport decode (output dec_pc);
    modport branch_unit (output branch_taken, prediction_dec, branch_ex, ex_pc, njump_pc, jump_pc);

endinterface

interface func_unit_ex_interface;
    logic new_request_dec;
    logic new_request;
    logic ready;
    
    modport decode (input ready, output new_request_dec, new_request);
    modport unit (output ready, input new_request_dec, new_request);
endinterface

// SystemVerilog does not permit dynamic indexing of arrays of interfaces so to mux between signals
// of an array of interfaces it is necessary to aggregate them in one interface and mux the aggregate signals instead
// The units instantiate a generic interface who's signal names must match those below in the unit modport
// Alternative would be to use structs instead
//interface writeback_unit_interface;
//    logic done [NUM_WB_UNITS-1:0];
//    logic early_done [NUM_WB_UNITS-1:0];
//    
//    logic accepted [NUM_WB_UNITS-1:0];
//    logic [XLEN-1:0] rd [NUM_WB_UNITS-1:0];
//
//    genvar i;
//    for (i=0; i< NUM_WB_UNITS; i++) begin : member
//        modport unit (output .done(done[i]), .early_done(early_done[i]), .rd(rd[i]), input .accepted(accepted[i]));
//    end
//     
//    modport writeback (input done, early_done, rd, output accepted);
//endinterface

//Dummy interface can be used to compile a single unit as top-level for development purposes
interface unit_writeback_interface;
    logic done ;
    logic early_done;
    logic accepted;
    logic [XLEN-1:0] rd;
    modport writeback (input done, early_done, rd, output accepted);
    modport unit (output done, early_done, rd, input accepted);
endinterface

//********************************

interface csr_exception_interface;
    logic valid;
    exception_code_t code;
    logic [31:0] pc;
    logic [31:0] addr;
    
    logic illegal_instruction; //invalid CSR, invalid CSR op, or priviledge
    logic[31:0] csr_pc;
    
    modport csr (input valid, code, pc, addr, output illegal_instruction, csr_pc);
    modport econtrol (output valid, code, pc, addr, input illegal_instruction, csr_pc);
    
endinterface


interface csr_inputs_interface;
    logic [XLEN-1:0] rs1;
    logic [11:0] csr_addr;
    logic system_op; //fn3 == 3'b000
    logic [1:0] csr_op;
    
    logic zero_operand;//(rs1 == x0 or zimm[4:0] == 4'b0000) and RS/RC or RSI/RCI
    
    modport decode (output rs1, csr_addr, system_op, csr_op, zero_operand);
    modport unit (input rs1, csr_addr, system_op, csr_op, zero_operand);
endinterface


interface register_file_decode_interface;
    logic[4:0] future_rd_addr; //if not a storing instruction required to be zero
    logic[4:0] rs1_addr;
    logic[XLEN-1:0] rs1;
    logic[4:0] rs2_addr; //if not used required to be zero
    logic[XLEN-1:0] rs2;
    instruction_id_t id;
    logic rs1_conflict;
    logic rs2_conflict;
    logic rd_conflict;
    logic instruction_issued;

    modport decode (output future_rd_addr, rs1_addr, rs2_addr, instruction_issued, id, input rs1_conflict, rs2_conflict, rd_conflict, rs1, rs2);
    modport unit (input future_rd_addr, rs1_addr, rs2_addr, instruction_issued, id, output rs1_conflict, rs2_conflict, rd_conflict, rs1, rs2);
endinterface


interface register_file_writeback_interface;
    logic[4:0] rd_addr;
    logic[4:0] rd_addr_early;
    logic valid_write;
    logic valid_write_early;
    
    logic[XLEN-1:0] rd_data;
    instruction_id_t id;
    instruction_id_t id_early;

    modport writeback (output rd_addr, rd_addr_early, valid_write, valid_write_early, rd_data, id, id_early);
    modport unit (input rd_addr, rd_addr_early, valid_write, valid_write_early, rd_data, id, id_early);
    
endinterface

interface exception_wb_interface_wb;
    logic exception;
    logic [3:0] exception_code;
    logic [31:0] exception_addr;
    modport wb (output exception, exception_code, exception_addr);
    modport csr (input exception, exception_code, exception_addr);
endinterface


interface instruction_queue_interface;
    logic[INSTRUCTION_QUEUE_DEPTH-1:0] pop;   
    logic[INSTRUCTION_QUEUE_DEPTH-1:0] shift_pop;   
    logic new_issue;
    
    instruction_queue_packet data_in;
    instruction_queue_packet[INSTRUCTION_QUEUE_DEPTH-1:0] data_out;
    logic [INSTRUCTION_QUEUE_DEPTH-1:0] valid;
    
    modport queue (input pop, data_in, new_issue, output data_out, shift_pop, valid);
    modport decode (output data_in, new_issue);
    modport wb (input data_in, shift_pop, valid, data_out, output pop);

endinterface


interface id_generator_interface;
    logic complete;
    instruction_id_t complete_id;
    
    logic advance;
    instruction_id_t issue_id;
    logic id_avaliable;

    modport generator (input complete, complete_id, advance, output issue_id, id_avaliable);
    modport decode (input issue_id, id_avaliable, output advance);
    modport wb (output complete, complete_id);

endinterface

interface instruction_buffer_interface;
    logic push;
    logic pop;
    logic flush;
    instruction_buffer_packet data_in;
    instruction_buffer_packet data_out;
    logic valid;
    logic full;
    logic early_full;
    
    modport buffer (input push, pop, flush, data_in, output data_out, valid, full, early_full);
    modport fetch (input full, early_full, output push, data_in, flush);
    modport decode (input valid, data_out, output pop);
    //modport exception_control (output flush);
endinterface


interface fifo_interface #(parameter DATA_WIDTH = 32);//#(parameter type data_type = logic[31:0]);
    logic push;
    logic pop;   
    logic [DATA_WIDTH-1:0] data_in;
    logic [DATA_WIDTH-1:0] data_out;
    logic valid;
    logic full;
    logic empty;
    logic early_full;
    logic early_valid;
    modport enqueue (input  early_full, full, empty, output data_in, push);
    modport dequeue (input early_valid, valid, data_out, output pop);
    modport structure(input push, pop, data_in, output data_out, early_valid, valid, early_full, full, empty);
endinterface

interface axi_interface;
    
    logic arready;
    logic arvalid;
    logic [C_M_AXI_ADDR_WIDTH-1:0] araddr;
    logic [7:0] arlen;
    logic [2:0] arsize;
    logic [1:0] arburst;
    logic [3:0] arcache;
    logic [5:0] arid;
    
    //read data
    logic rready;
    logic rvalid;
    logic [C_M_AXI_DATA_WIDTH-1:0] rdata;
    logic [1:0] rresp;
    logic rlast;
    logic [5:0] rid;

    //Write channel
    //write address
    logic awready;
    logic awvalid;
    logic [C_M_AXI_ADDR_WIDTH-1:0] awaddr;
    logic [7:0] awlen;
    logic [2:0] awsize;
    logic [1:0] awburst;
    logic [3:0] awcache;
    logic [5:0] awid;

    //write data
    logic wready;
    logic wvalid;
    logic [C_M_AXI_DATA_WIDTH-1:0] wdata;
    logic [(C_M_AXI_DATA_WIDTH/8)-1:0] wstrb;
    logic wlast;

    //write response
    logic bready;
    logic bvalid;
    logic [1:0] bresp;
    logic [5:0] bid;
        
    modport master (input arready, rvalid, rdata, rresp, rlast, rid, awready, wready, bvalid, bresp, bid,
            output arvalid, araddr, arlen, arsize, arburst, arcache, arid, rready, awvalid, awaddr, awlen, awsize, awburst, awcache, awid,
            wvalid, wdata, wstrb, wlast, bready);
    

    modport slave (input arvalid, araddr, arlen, arsize, arburst, arcache,
            rready,
            awvalid, awaddr, awlen, awsize, awburst, awcache, arid,
            wvalid, wdata, wstrb, wlast, awid, 
            bready,
            output arready, rvalid, rdata, rresp, rlast, rid,
            awready,
            wready,
            bvalid, bresp, bid);

endinterface

interface avalon_interface;
    logic [31:0] addr;
    logic read;
    logic write;
    logic [3:0] byteenable;
    logic [31:0] readdata;
    logic [31:0] writedata;
    logic waitrequest;
    logic readdatavalid;
    logic writeresponsevalid;
    
    modport master (input readdata, waitrequest, readdatavalid, writeresponsevalid,
            output addr, read, write, byteenable, writedata);
    modport slave (output readdata, waitrequest, readdatavalid, writeresponsevalid,
            input addr, read, write, byteenable, writedata);
    
endinterface
    
//interface l1_arbiter_request_interface;
//    logic [31:2] addr [3:0];
//    logic [31:0] data [3:0];
//    logic rnw [3:0];
//    logic [0:3] be [3:0];
//    logic [2:0] size [3:0];
//    logic con [3:0];
//    
//    logic request [3:0];
//    logic ack [3:0];
//    
//    for (genvar i=0; i< NUM_WB_UNITS; i++) begin : member
//        modport requester (output .addr(addr[i]), .data(data[i]), .rnw(rnw[i]), .be(be[i]), .size(size[i]), .con(con[i]), .request(request[i]), input .ack(ack[i]));
//    end
//    
//    modport arb (input addr, data, rnw, be, size, con, request, output ack);
//endinterface

interface l1_arbiter_request_interface;
    logic [31:0] addr;
    logic [31:0] data ;
    logic rnw ;
    logic [0:3] be;
    logic [2:0] size;
    logic is_amo;
    logic [4:0] amo;
   
    logic request;
    logic ack;
    
    modport requester (output addr, data, rnw, be, size, is_amo, amo, request, input ack);
    
    modport arb (input addr, data, rnw, be, size, is_amo, amo, request, output ack);
endinterface


interface l1_arbiter_return_interface;
    logic [31:2] inv_addr;
    logic inv_valid;
    logic inv_ack;
    logic [31:0] data;
    logic data_valid;
    
    modport requester (input inv_addr, inv_valid, data, data_valid, output inv_ack);
    modport arb (output inv_addr, inv_valid, data, data_valid, input inv_ack);
    
    
endinterface


interface mmu_interface;
    //From TLB
    logic new_request;
    logic execute;
    logic rnw;
    logic [31:0] virtual_address;
    
    //TLB response
    logic write_entry;
    logic [19:0] new_phys_addr;
    
    //From CSR
    logic [21:0] ppn;
    logic mxr; //Make eXecutable Readable
    logic pum; //Protect User Memory
    logic privilege;

    modport mmu (input virtual_address, new_request, execute, rnw, ppn, mxr, pum, privilege, output write_entry, new_phys_addr);
    modport tlb (input write_entry, new_phys_addr, output new_request, virtual_address, execute, rnw);   
    modport csr (output ppn, mxr, pum, privilege);
    
endinterface

interface tlb_interface;
    logic [31:0] virtual_address;
    logic new_request;
    logic rnw;
    logic execute;
    
    logic complete;
    logic [31:0] physical_address;
        
    logic flush;
    logic flush_complete;
    
    modport tlb (input virtual_address, flush, rnw, execute,   output complete, physical_address, flush_complete);
    modport mem  (output new_request, virtual_address, rnw, execute, input complete, physical_address);
    modport fence (output flush, input flush_complete);

endinterface


interface ls_sub_unit_interface;
    logic data_valid;
    logic ready;
    logic new_request;
    logic ack;
    
    modport sub_unit (input ack, new_request, output data_valid, ready);
    modport ls (output ack, new_request, input data_valid, ready);
    
endinterface


interface fetch_sub_unit_interface;
    logic [31:0] stage1_addr;
    logic [31:0] stage2_addr;

    logic [31:0] data_out;
    logic data_valid;
    logic ready;
    logic new_request;
    
    modport sub_unit (input stage1_addr, stage2_addr,  new_request, output data_out, data_valid, ready);
    modport fetch (output stage1_addr, stage2_addr,  new_request, input data_out, data_valid, ready);
    
endinterface




