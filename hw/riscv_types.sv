//(C) 2017 Eric Matthews, Lesley Shannon.  All rights reserved.
package riscv_types;
    import riscv_config::*;
        
    typedef enum bit [6:0] {
        LUI = 7'b0110111,
        AUIPC = 7'b0010111,
        JAL = 7'b1101111,
        JALR = 7'b1100111,
        BRANCH = 7'b1100011,
        LOAD = 7'b0000011,
        STORE = 7'b0100011,
        ARITH_IMM = 7'b0010011,
        ARITH = 7'b0110011,//include mul/div
        FENCE = 7'b0001111,
        AMO = 7'b0101111,
        SYSTEM = 7'b1110011,
        BIT = 7'b1010111
        //end of RV32I
    } opcodes_t;
    
    typedef enum bit [2:0] {
        ADD_SUB_fn3 = 3'b000,
        SLL_fn3 = 3'b001,
        SLT_fn3 = 3'b010,
        SLTU_fn3 = 3'b011,
        XOR_fn3 = 3'b100,
        OR_fn3 = 3'b110,
        SRA_fn3 = 3'b101,
        AND_fn3 = 3'b111
    } fn3_arith_t;

    typedef enum bit [2:0] {
        LS_B_fn3 = 3'b000,
        LS_H_fn3 = 3'b001,
        LS_W_fn3 = 3'b010,
        //unused 011
        L_BU_fn3 = 3'b100,
        L_HU_fn3 = 3'b101
        //unused 110
        //unused 111
    } fn3_ls_t;

    typedef enum bit [2:0] {
        BEQ_fn3 = 3'b000,
        BNE_fn3 = 3'b001,
        //010 unused
        //011 unused
        BLT_fn3 = 3'b100,
        BGE_fn3 = 3'b101,
        BLTU_fn3 = 3'b110,
        BGEU_fn3 = 3'b111
    } fn3_branch_t;

    
    typedef enum bit [2:0] {
        MUL_fn3 = 3'b000,
        MULH_fn3 = 3'b001,
        MULHSU_fn3 = 3'b010,
        MULHU_fn3 = 3'b011,
        DIV_fn3 = 3'b100,
        DIVU_fn3 = 3'b101,
        REM_fn3 = 3'b110,
        REMU_fn3 = 3'b111
    } fn3_mul_div_t;    
    
    typedef enum bit [11:0] {
        //Machine info
        MVENDORID = 12'hF11,
        MARCHID = 12'hF12,
        MIMPID = 12'hF13,
        MHARTID = 12'hF14,
        //Machine trap setup
        MSTATUS = 12'h300,
        MISA = 12'h301,
        MEDELEG = 12'h302,
        MIDELEG = 12'h303,
        MIE = 12'h304,
        MTVEC = 12'h305,
        //Machine trap handling
        MSCRATCH = 12'h340,
        MEPC = 12'h341,
        MCAUSE = 12'h342,
        MBADADDR = 12'h343,
        MIP = 12'h344,
    
        //Machine Counters
        MCYCLE = 12'hB00,
        MTIME = 12'hB01,
        MINSTRET = 12'hB02,
        MCYCLEH = 12'hB80,
        MTIMEH = 12'hB81,
        MINSTRETH = 12'hB82,
        
        //Machine Counter setup
        MUCOUNTEREN = 12'h310,
        MSCOUNTEREN = 12'h311,

        //Deltas
        MUCYCLE_DELTA = 12'h700,
        MUTIME_DELTA = 12'h701,
        MUINSTRET_DELTA = 12'h702,
        MSCYCLE_DELTA = 12'h704,
        MSTIME_DELTA = 12'h705,
        MSINSTRET_DELTA = 12'h706,        
        MUCYCLE_DELTAH = 12'h780,
        MUTIME_DELTAH = 12'h781,
        MUINSTRET_DELTAH = 12'h782,
        MSCYCLE_DELTAH = 12'h784,
        MSTIME_DELTAH = 12'h785,
        MSINSTRET_DELTAH = 12'h786,    
        //Supervisor regs
        //Supervisor Trap Setup
        SSTATUS = 12'h100,
        SEDELEG = 12'h102,
        SIDELEG = 12'h103,
        SIE = 12'h104,
        STVEC = 12'h105,
        
        //Supervisor trap handling
        SSCRATCH = 12'h140,
        SEPC = 12'h141,
        SCAUSE = 12'hD42,
        SBADADDR = 12'hD43,
        SIP = 12'h144,
               
        //Supervisor Protection and Translation
        SPTBR = 12'h180,
        
        //Supervisor counters
        SCYCLE = 12'hD00,
        STIME = 12'hD01,
        SINSTRET = 12'hD02,
        SCYCLEH = 12'hD80,
        STIMEH = 12'hD81,
        SINSTRETH = 12'hD82,
    
        //User regs       
        //USER Floating Point
        FFLAGS = 12'h001,
        FRM = 12'h002,
        FCSR = 12'h003,
        //User Counter Timers
        CYCLE = 12'hC00,
        TIME = 12'hC01,
        INSTRET = 12'hC02,
        CYCLEH = 12'hC80,
        TIMEH = 12'hC81,
        INSTRETH = 12'hC82
    } csr_t;

    typedef enum bit [2:0] {
        NONCSR_fn3 = 3'b000,
        RW_fn3 = 3'b001,
        RS_fn3 = 3'b010,
        RC_fn3 = 3'b011,
        // unused  3'b100,
        RWI_fn3 = 3'b101,
        RSI_fn3 = 3'b110,
        RCI_fn3 = 3'b111
    } fn3_csr_t;

    typedef enum bit [1:0] {
        CSR_RW = 2'b01,
        CSR_RS = 2'b10,
        CSR_RC = 2'b11
    } csr_op_t;

    const bit[1:0] CSR_READ_ONLY = 2'b11;

    typedef enum bit [1:0] {
        USER = 2'b00,
        SUPERVISOR = 2'b01,
        HYPERVISOR =2'b10,
        MACHINE = 2'b11
    } privilege_t;


    typedef enum bit [4:0] {
        BARE = 5'd0,
        SV32 = 5'd8
    } vm_t;

    typedef enum bit [3:0] {
        INST_ADDR_MISSALIGNED = 4'd0,
        INST_FAULT = 4'd1,
        ILLEGAL_INST = 4'd2,
        BREAK = 4'd3,
        LOAD_ADDR_MISSALIGNED = 4'd4,
        LOAD_FAULT = 4'd5,
        STORE_AMO_ADDR_MISSALIGNED = 4'd6,
        STORE_AMO_FAULT = 4'd7,
        ECALL_U = 4'd8,
        ECALL_S = 4'd9,
        ECALL_H = 4'd10,
        ECALL_M = 4'd11
    } exception_code_t;
    parameter ECODE_W = 4;
    

    typedef enum bit [3:0] {
        U_SOFTWARE_INTERRUPT = 4'd0,
        S_SOFTWARE_INTERRUPT = 4'd1,
        H_SOFTWARE_INTERRUPT = 4'd2,
        M_SOFTWARE_INTERRUPT = 4'd3,
        U_TIMER_INTERRUPT = 4'd4,
        S_TIMER_INTERRUPT = 4'd5,
        H_TIMER_INTERRUPT = 4'd6,
        M_TIMER_INTERRUPT = 4'd7,
        U_EXTERNAL_INTERRUPT = 4'd8,
        S_EXTERNAL_INTERRUPT = 4'd9,
        H_EXTERNAL_INTERRUPT = 4'd10,
        M_EXTERNAL_INTERRUPT = 4'd11
    } interrupt_code_t;

    
    typedef enum bit [1:0] {
        ALU_SLT = 2'b00,
        ALU_LOGIC = 2'b01,        
        ALU_SHIFT =2'b10,
        ALU_ADD_SUB = 2'b11
    } alu_op_t;    
    
    typedef logic[$clog2(INSTRUCTION_QUEUE_DEPTH)-1:0] instruction_id_t;
    
    
    typedef struct packed{
        logic [WB_UNITS_WIDTH-1:0] unit_id;
        logic [4:0] rd_addr;
        instruction_id_t id;
    } instruction_queue_packet;

    typedef struct packed{
        logic [31:0] instruction;
        logic [31:0] pc;
        logic uses_rs1;
        logic uses_rs2;
        logic uses_rd;
        logic prediction;
    } instruction_buffer_packet;

    
    typedef struct packed{
        logic [XLEN-1:0] in1;
        logic [XLEN-1:0] in2;
        logic [2:0] fn3;
        logic add;
        logic arith;
        logic left_shift;
        logic [XLEN-1:0] shifter_in;
        logic sltu;
        logic using_pc;
        logic [1:0] op;
    }alu_inputs_t;     
    
    
     typedef struct packed{
        logic [XLEN-1:0] rs1;
        logic [2:0] fn3;
    }bit_inputs_t;    
    
    typedef struct packed{
        logic [XLEN-1:0] rs1;
        logic [XLEN-1:0] rs2;
        logic [2:0] fn3;
        logic [31:0] dec_pc;
        logic use_signed;
        logic jal;
        logic jalr;
        logic branch_compare;
        logic[19:0] jal_imm;
        logic[11:0] jalr_imm;
        logic[11:0] br_imm;
        logic prediction;
    } branch_inputs_t;            
    
    
    typedef enum bit [4:0] {
        AMO_LR = 5'b00010,
        AMO_SC = 5'b00011,
        AMO_SWAP = 5'b00001,
        AMO_ADD = 5'b00000,
        AMO_XOR = 5'b00100,
        AMO_AND = 5'b01100,
        AMO_OR = 5'b01000,
        AMO_MIN = 5'b10000,
        AMO_MAX = 5'b10100,
        AMO_MINU = 5'b11000,
        AMO_MAXU = 5'b11100
    } amo_t;    
    
    typedef struct packed{
        logic [XLEN-1:0] rs1_load;
        logic [XLEN-1:0] rs2;
        logic [4:0] op;
    }amo_alu_inputs_t;     
    
    
    typedef struct packed{
        logic [XLEN-1:0] virtual_address;
        logic [XLEN-1:0] rs2;
        logic [31:0] pc;
        logic [2:0] fn3;
        logic [4:0] amo;
        logic is_amo;
        logic load;
        logic store;
        logic load_store_forward;
    } load_store_inputs_t;    
    
    typedef struct packed{
        logic [XLEN-1:0] rs1;
        logic [XLEN-1:0] rs2;
        logic [1:0] op;
    } mul_inputs_t;        
    
    typedef struct packed{
        logic [XLEN-1:0] rs1;
        logic [XLEN-1:0] rs2;
        logic [1:0] op;
        logic reuse_result;
        logic overflow;
        logic div_zero;    
    } div_inputs_t;        
    
    typedef struct packed{
        logic [31:2] addr;
        logic [31:0] data;
        logic rnw;
        logic [0:3] be;
        logic [2:0] size;
        logic con;
    } to_l1_arbiter_packet;
    
    typedef struct {
        logic [31:0] addr;
        logic load;
        logic store;
        logic [3:0] be;
        logic [31:0] data_in;
    } data_access_shared_inputs_t;
    
endpackage


