//(C) 2017 Eric Matthews, Lesley Shannon.  All rights reserved.
import riscv_config::*;
import riscv_types::*;

module riscv ( 
        input logic clk,
        input logic rst,
    
        bram_interface.user instruction_bram,
        bram_interface.user data_bram,
        
        axi_interface.master m_axi,
        avalon_interface.master m_avalon,
    
    
        //To L2 Arbiter
        output logic from_cpu_addr_push,
        output logic [45:0] from_cpu_addr_data,
        input logic to_cpu_addr_full,
            
        output logic from_cpu_data_push,
        output logic [31:0] from_cpu_data_data,
        input logic to_cpu_data_full,
    
        //From L2 Arbiter
        output logic from_cpu_data_pop,
        input logic [33:0] to_cpu_data_data,
        input logic to_cpu_data_valid,
            
        output logic from_cpu_inv_pop,
        input logic [29:0] to_cpu_inv_data,
        input logic to_cpu_inv_valid,
    
        output logic from_cpu_con_pop,
        input logic  to_cpu_con_data,
        input logic to_cpu_con_valid,
            
    
        input logic interrupt,
    
        //decode unused
        output logic illegal_instruction,
    
        //load store unused
        output logic unaligned_addr,
    
        output instruction_issued,
        
        output logic[31:0] if2_pc_debug,
        output logic[31:0] dec_pc_debug

        );
        
    l1_arbiter_request_interface l1_request[3:0]();
    l1_arbiter_return_interface l1_response[3:0]();
    logic sc_complete;
    logic sc_success;
        
    branch_table_interface bt();    
    
    register_file_decode_interface rf_decode();
    alu_inputs_t alu_inputs;
    load_store_inputs_t ls_inputs;
    branch_inputs_t branch_inputs;
    mul_inputs_t mul_inputs;
    div_inputs_t div_inputs;
    bit_inputs_t bit_inputs;

    csr_inputs_interface csr_inputs();

    func_unit_ex_interface branch_ex();    
    func_unit_ex_interface alu_ex();
    func_unit_ex_interface ls_ex();
    func_unit_ex_interface csr_ex();
    func_unit_ex_interface mul_ex();
    func_unit_ex_interface div_ex();
    func_unit_ex_interface bit_ex();


    instruction_buffer_interface ib();
    instruction_queue_interface iq();
    id_generator_interface id_gen();   
    
    unit_writeback_interface unit_wb [NUM_WB_UNITS-1:0]();   

    //writeback_unit_interface unit_wb();
   
    register_file_writeback_interface rf_wb();
    
    csr_exception_interface csr_exception();
    
    tlb_interface itlb();
    tlb_interface dtlb();
    logic tlb_on;
    logic [9:0] asid;
    logic return_from_exception;
     
    mmu_interface immu();
    mmu_interface dmmu();

    logic inorder;
    
    
    //Branch Unit and Fetch Unit
    logic branch_taken;
    logic [31:0] pc_offset;
    logic[31:0] jalr_rs1;
    logic jalr;
        
    //Decode Unit and Fetch Unit
    logic [31:0] if2_pc;
    logic [31:0] instruction;
    logic dec_advance;
    logic flush;
    
    logic [31:0] dec_pc;
    logic [31:0] pc_ex;
    logic [2:0] fn3_dec;

    logic instruction_issued_no_rd;
    logic instruction_complete;

    assign instruction_issued = dec_advance;
    
    
    assign if2_pc_debug = if2_pc;
    assign dec_pc_debug = dec_pc;

    
    /*************************************
     * Memory Interface
     *************************************/
    //l1_arbiter arb(.*);
    
    /*************************************
     * CPU Front end
     *************************************/
    branch_table bt_block (.*);
    fetch fetch_block (.*, .icache_on('1), .tlb(itlb), .l1_request(l1_request[L1_ICACHE_ID]), .l1_response(l1_response[L1_ICACHE_ID]), .exception(1'b0));
    //tlb_lut_ram #(ITLB_WAYS, ITLB_DEPTH) i_tlb (.*, .tlb(itlb), .mmu(immu));
    //mmu i_mmu (.*,  .mmu(immu) , .l1_request(l1_request[L1_IMMU_ID]), .l1_response(l1_response[L1_IMMU_ID]), .mmu_exception());
    //TLB bypass
    assign itlb.complete = 1;
    assign itlb.physical_address = itlb.virtual_address;
    instruction_buffer inst_buffer(.*);
    
    /*************************************
     * Decode/Issue/Control
     *************************************/
    decode decode_block (.*);
    register_file register_file_block (.*);
    id_generator id_gen_block (.*);
    instruction_queue inst_queue(.*);
    
    /*************************************
     * Units
     *************************************/
    branch_unit branch_unit_block (.*, .branch_wb(unit_wb[BRANCH_UNIT_ID].unit));
    alu_unit alu_unit_block (.*, .alu_wb(unit_wb[ALU_UNIT_ID].unit));
    load_store_unit load_store_unit_block (.*, .dcache_on(1), .clear_reservation(0), .tlb(dtlb), .ls_wb(unit_wb[LS_UNIT_ID].unit), .l1_request(l1_request[L1_DCACHE_ID]), .l1_response(l1_response[L1_DCACHE_ID]));
    //TLB bypass
    assign dtlb.complete = 1;
    assign dtlb.physical_address = dtlb.virtual_address;
    //tlb_lut_ram #(DTLB_WAYS, DTLB_DEPTH) d_tlb (.*, .tlb(dtlb), .mmu(dmmu));
    //mmu d_mmu (.*, .mmu(dmmu), .l1_request(l1_request[L1_DMMU_ID]), .l1_response(l1_response[L1_DMMU_ID]), .mmu_exception());
    csr_unit csr_unit_block (.*, .csr_wb(unit_wb[CSR_UNIT_ID].unit));
    mul_unit mul_unit_block (.*, .mul_wb(unit_wb[MUL_UNIT_ID].unit));
    div_unit div_unit_block (.*, .div_wb(unit_wb[DIV_UNIT_ID].unit));
    bitops_unit bitops_unit_block (
        .clk(clk),
        .rst(rst),
        
        .new_request_dec(bit_ex.new_request_dec),
        .new_request(bit_ex.new_request),
        .ready(bit_ex.ready),
  
        .rs1(bit_inputs.rs1),
        .fn3(bit_inputs.fn3),
        .fn3_dec(fn3_dec),
        
        .early_done(unit_wb[BIT_UNIT_ID].early_done),
        .accepted(unit_wb[BIT_UNIT_ID].accepted),
        .rd(unit_wb[BIT_UNIT_ID].rd)
    );

  
    /*************************************
     * Writeback Mux
     *************************************/
    write_back write_back_mux (.*);
    
endmodule
