//(C) 2017 Eric Matthews, Lesley Shannon.  All rights reserved.
package riscv_config;

    parameter FPGA_VENDOR = "altera"; //xilinx or altera
    
    parameter XLEN = 32;
    parameter ADDR_W = 32;    
    
    parameter CPU_ID = 0;//32 bit value

    parameter bit[31:0] RESET_VEC = 32'h80000000;
    parameter ASIDLEN = 10;//pid
    parameter PAGE_ADDR_W = 12;
        
    parameter TIMER_W = 48; //32 days @ 100MHz

    parameter USE_VARIABLE_LATENCY_DIV = 1;
    
    parameter NUM_WB_UNITS = 7;
    parameter WB_UNITS_WIDTH = $clog2(NUM_WB_UNITS);

   typedef enum {//bit [WB_UNITS_WIDTH-1:0] {
        ALU_UNIT_ID = 0,
        BRANCH_UNIT_ID=1,
        CSR_UNIT_ID = 2,
        LS_UNIT_ID = 3,
        MUL_UNIT_ID = 4,
        DIV_UNIT_ID = 5,
        BIT_UNIT_ID = 6
    } unit_ids;
        
    parameter INSTRUCTION_QUEUE_DEPTH = 2;
    parameter FETCH_BUFFER_DEPTH = 4;
    
    parameter LS_INPUT_BUFFER_DEPTH=4;
    parameter LS_OUTPUT_BUFFER_DEPTH=2;
    
    parameter DIV_INPUT_BUFFER_DEPTH=2;
    parameter DIV_OUTPUT_BUFFER_DEPTH=2;
    
    
    //Address space
    parameter SCRATCH_ADDR_L = 32'h80000000;
    parameter SCRATCH_ADDR_H = 32'h8000FFFF;
    parameter SCRATCH_BIT_CHECK = 16;
        
    parameter MEMORY_ADDR_L = 32'h20000000;
    parameter MEMORY_ADDR_H = 32'h3FFFFFFF;
    parameter MEMORY_BIT_CHECK = 4;
    
    parameter BUS_ADDR_L = 32'h60000000;
    parameter BUS_ADDR_H = 32'h6FFFFFFF;
    parameter BUS_BIT_CHECK = 4;
    
    //Bus
    parameter C_M_AXI_ADDR_WIDTH = 32;
    parameter C_M_AXI_DATA_WIDTH = 32;
    
    //Caches
    //Size in bytes: (DCACHE_LINES * DCACHE_WAYS * DCACHE_LINE_W * 4)
    parameter DCACHE_LINES = 256;
    parameter DCACHE_WAYS = 4;
    parameter DCACHE_LINE_ADDR_W = $clog2(DCACHE_LINES);
    parameter DCACHE_LINE_W = 4; //In words
    parameter DCACHE_SUB_LINE_ADDR_W = $clog2(DCACHE_LINE_W);
    parameter DCACHE_TAG_W = ADDR_W - DCACHE_LINE_ADDR_W - DCACHE_SUB_LINE_ADDR_W - 2;

    parameter DTLB_WAYS = 2;
    parameter DTLB_DEPTH = 64;
    
    
    //Size in bytes: (ICACHE_LINES * ICACHE_WAYS * ICACHE_LINE_W * 4)
    //For optimal BRAM packing lines should not be less than 512
    parameter ICACHE_LINES = 1024;
    parameter ICACHE_WAYS = 2;
    parameter ICACHE_LINE_ADDR_W = $clog2(ICACHE_LINES);
    parameter ICACHE_LINE_W = 8; //In words
    parameter ICACHE_SUB_LINE_ADDR_W = $clog2(ICACHE_LINE_W);
    parameter ICACHE_TAG_W = ADDR_W - ICACHE_LINE_ADDR_W - ICACHE_SUB_LINE_ADDR_W - 2;
    
    parameter BRANCH_TABLE_ENTRIES = 1024;

    parameter ITLB_WAYS = 2;
    parameter ITLB_DEPTH = 32;
    
    typedef enum bit [1:0] {
        L1_DCACHE_ID = 2'd0,
        L1_DMMU_ID = 2'd1,
        L1_ICACHE_ID = 2'd2,
        L1_IMMU_ID = 2'd3
    } l1_connection_id;
    
    
    typedef enum bit [2:0] {
        SIZE_1 = 3'd0,
        SIZE_4 = 3'd1,
        SIZE_8 = 3'd2,
        SIZE_16 = 3'd3,
        SIZE_32 = 3'd4,
        SIZE_64 = 3'd5
    } l2_burst_size_t;
    
    function bit[2:0] getL2BurstSize(input int line_width); 
        bit[2:0] value;

        if (line_width < 4)
            value = 0;
        else
            value = $clog2(line_width)-1;
                
        return value;
    endfunction

    
endpackage
