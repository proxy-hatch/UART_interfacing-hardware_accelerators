//(C) 2017 Eric Matthews, Lesley Shannon.  All rights reserved.
import riscv_config::*;
import riscv_types::*;

module decode(
        input logic clk,
        input logic rst,

        input logic flush,
            
        branch_table_interface.decode bt,        
        instruction_buffer_interface.decode ib,

        id_generator_interface.decode id_gen,
        
        register_file_decode_interface.decode rf_decode,
        instruction_queue_interface.decode iq,
        
        output alu_inputs_t alu_inputs,
        output load_store_inputs_t ls_inputs,
        output branch_inputs_t branch_inputs,
        csr_inputs_interface.decode csr_inputs,
        output mul_inputs_t mul_inputs,
        output  div_inputs_t div_inputs,
        output bit_inputs_t bit_inputs,
        output logic[2:0] fn3_dec,
        
        func_unit_ex_interface.decode alu_ex,
        func_unit_ex_interface.decode ls_ex,
        func_unit_ex_interface.decode branch_ex,
        func_unit_ex_interface.decode csr_ex,
        func_unit_ex_interface.decode mul_ex,
        func_unit_ex_interface.decode div_ex,
        func_unit_ex_interface.decode bit_ex,

        output instruction_issued_no_rd,
        input logic instruction_complete,
        
        output logic dec_advance,
        output logic [31:0] dec_pc,
        output logic illegal_instruction
    
        );
    
    logic [2:0] fn3;
    logic [6:0] opcode;
    logic [4:0] shamt;
    
    assign fn3 = ib.data_out.instruction[14:12];
    assign opcode = ib.data_out.instruction[6:0];
    assign shamt = ib.data_out.instruction[24:20];
    
    logic uses_rs1;
    logic uses_rs2;
    logic uses_rd;
    
    logic [4:0] rs1;
    logic [4:0] rs2;
    logic [4:0] future_rd_addr;
    
    logic issue_valid;
    logic store_issued_with_forwarding;
    logic operands_ready;
    logic operands_ready_non_store;
    
    logic csr_imm_op;
    logic sys_op;
    
    logic mult_div_op;
    
    logic branch_compare;
    
    logic new_branch_request;
    logic new_alu_request;
    logic new_ls_request;
    logic new_csr_request;
    logic new_mul_request;
    logic new_div_request;
    logic new_bit_request;

    logic issue_alu;
    logic issue_ls;
    logic issue_branch;
    logic issue_csr;
    logic issue_mul;
    logic issue_div;
    logic issue_bit;

    logic unit_available;
    logic advance;
        
    logic [XLEN-1:0] alu_rs1;
    logic [XLEN-1:0] alu_rs2;
    
    logic[1:0]  alu_op;
    logic[2:0]  alu_fn3;
        
    logic [31:0] ls_offset;
    logic [31:0] virtual_address;
    
    logic [4:0] load_rd;
    logic last_ls_request_was_load;
    logic load_store_forward;    
    
    logic [4:0] prev_div_rs1;
    logic [4:0] prev_div_rs2;
    logic prev_div_result_valid;
    
    assign dec_pc =  ib.data_out.pc;    
    
    assign csr_imm_op = (opcode == SYSTEM) && fn3[2];
    assign sys_op =  (opcode == SYSTEM) && (fn3 == 0);
    
    assign uses_rs1 = ib.data_out.uses_rs1;
    assign uses_rs2 = ib.data_out.uses_rs2;
    assign uses_rd = ib.data_out.uses_rd;
    
    assign rs1 = ib.data_out.instruction[19:15];
    assign rs2 = ib.data_out.instruction[24:20];
    assign future_rd_addr = ib.data_out.instruction[11:7];    
    
    //Register File interface inputs
    assign rf_decode.rs1_addr  =  rs1;
    assign rf_decode.rs2_addr  =  rs2;
    assign rf_decode.future_rd_addr  =  future_rd_addr;
    assign rf_decode.instruction_issued = advance & uses_rd;
    assign rf_decode.id = id_gen.issue_id;
    //Issue logic
    always_comb begin
        case (opcode)
            LUI : illegal_instruction = 1'b0;
            AUIPC : illegal_instruction = 1'b0;
            JAL : illegal_instruction = 1'b0;
            JALR : illegal_instruction = 1'b0;
            BRANCH : illegal_instruction = 1'b0;
            LOAD : illegal_instruction = 1'b0;
            STORE : illegal_instruction = 1'b0;
            ARITH_IMM : illegal_instruction = 1'b0;
            ARITH : illegal_instruction = 1'b0;
            FENCE : illegal_instruction = 1'b0;
            AMO : illegal_instruction = 1'b0;
            SYSTEM : illegal_instruction = 1'b0;
            default : illegal_instruction = 1'b1;
        endcase
    end

    always_comb begin
        if (new_mul_request)
            iq.data_in.unit_id = MUL_UNIT_ID;
        else if (new_div_request) 
            iq.data_in.unit_id = DIV_UNIT_ID;
        else if (new_ls_request) 
            iq.data_in.unit_id = LS_UNIT_ID;
        else if (new_csr_request) 
            iq.data_in.unit_id = CSR_UNIT_ID;
        else if (new_branch_request)
            iq.data_in.unit_id = BRANCH_UNIT_ID;
        else if (new_bit_request) 
            iq.data_in.unit_id = BIT_UNIT_ID;
        else
            iq.data_in.unit_id = ALU_UNIT_ID;
    end
    assign iq.data_in.rd_addr = future_rd_addr;
    assign iq.data_in.id = id_gen.issue_id;
    assign iq.new_issue = advance & uses_rd;    
    
    assign id_gen.advance = advance & uses_rd;

    assign bt.dec_pc = ib.data_out.pc;
    
    assign issue_valid = ib.valid & ((~uses_rd) | (uses_rd & id_gen.id_avaliable));
    
    
    assign operands_ready_non_store =  !(
            (uses_rs1 && rf_decode.rs1_conflict) ||
            (uses_rs2 && rf_decode.rs2_conflict));
    
    assign load_store_forward = ((opcode == STORE) && last_ls_request_was_load && (rs2 == load_rd));
    
    assign operands_ready =  !(
            (uses_rs1 && rf_decode.rs1_conflict) ||
            (uses_rs2 && rf_decode.rs2_conflict && ~load_store_forward));

    
    assign mult_div_op = (opcode == ARITH) && ib.data_out.instruction[25];
    assign branch_compare = (opcode == BRANCH);
    
    assign new_branch_request =  ((opcode == BRANCH) || (opcode == JAL) || (opcode == JALR));
    assign new_alu_request =  (((opcode == ARITH)  && ~ib.data_out.instruction[25]) || (opcode== ARITH_IMM)  || (opcode == AUIPC) || (opcode == LUI));
    assign new_ls_request = (opcode == LOAD || opcode == STORE || opcode == AMO);
    assign new_csr_request = (opcode == SYSTEM);
    assign new_mul_request = mult_div_op & ~fn3[2] ;
    assign new_div_request =mult_div_op & fn3[2] ;
    assign new_bit_request = (opcode == BIT);

    
    assign issue_branch = issue_valid & operands_ready_non_store & new_branch_request & branch_ex.ready & ~flush;
    assign issue_alu = issue_valid & operands_ready_non_store & new_alu_request & alu_ex.ready & ~flush;
    assign issue_ls = issue_valid & operands_ready & new_ls_request & ls_ex.ready & ~flush;
    assign issue_csr = issue_valid & operands_ready_non_store & new_csr_request & csr_ex.ready & ~flush;
    assign issue_mul = issue_valid & operands_ready_non_store & new_mul_request & mul_ex.ready & ~flush;
    assign issue_div = issue_valid & operands_ready_non_store & new_div_request & div_ex.ready & ~flush;
    assign issue_bit = issue_valid & operands_ready_non_store & new_bit_request & bit_ex.ready & ~flush;

    assign unit_available =  (
            (new_branch_request & (branch_ex.ready | branch_compare)) |
            (new_alu_request & alu_ex.ready) |
            (new_ls_request & ls_ex.ready) |
            ( new_csr_request & csr_ex.ready) |
            (new_mul_request & mul_ex.ready) |
            (new_div_request & div_ex.ready)  |
            (new_bit_request & bit_ex.ready)            
        );
    
    assign advance =  issue_valid & operands_ready & unit_available & ~flush;
    
    assign ib.pop = advance;
    assign dec_advance = advance;
    assign instruction_issued_no_rd = advance & ~uses_rd;
    
    //----------------------------------------------------------------------------------
    //ALU unit inputs
    //----------------------------------------------------------------------------------
    assign alu_ex.new_request_dec = issue_alu;
    
    always_comb begin  
        if ((opcode == AUIPC))
            alu_rs1 = ib.data_out.pc;
        else if (opcode == LUI)
            alu_rs1 = '0;
        else
            alu_rs1 = rf_decode.rs1;
    end
    
    always_comb begin  
        if ((opcode == AUIPC) || (opcode == LUI))
            alu_rs2 = {ib.data_out.instruction[31:12], 12'b0};
        else if (opcode == ARITH_IMM)
            alu_rs2 = 32'(signed'(ib.data_out.instruction[31:20]));
        else// ARITH instructions
            alu_rs2 = rf_decode.rs2;
    end
    
    assign alu_fn3 = ((opcode == AUIPC) || (opcode == LUI)) ? ADD_SUB_fn3 : fn3; //put lui and auipc through adder path
    always_comb begin
        case (alu_fn3)
            SLT_fn3 : alu_op = ALU_SLT;
            SLTU_fn3 : alu_op = ALU_SLT;            
            SLL_fn3 : alu_op = ALU_SHIFT;
            XOR_fn3 : alu_op = ALU_LOGIC;
            OR_fn3 : alu_op = ALU_LOGIC;
            AND_fn3 : alu_op = ALU_LOGIC;            
            SRA_fn3 : alu_op = ALU_SHIFT;
            ADD_SUB_fn3 : alu_op = ALU_ADD_SUB;
        endcase
    end
        
    logic [XLEN-1:0] left_shift_in;
    //assign left_shift_in =  {<<{rf_decode.rs1}}; //Bit reverse not supported by Altera
	 always_comb begin
		for (int i=0; i < XLEN; i=i+1) begin
			left_shift_in[i] = rf_decode.rs1[XLEN-i-1];
		end
	 end
    always_ff @(posedge clk) begin
        if (issue_alu) begin
            alu_inputs.in1 <= alu_rs1;
            alu_inputs.in2 <= alu_rs2;
            alu_inputs.fn3 <= fn3;
            alu_inputs.add <= ~((opcode == ARITH && ib.data_out.instruction[30]) || ((opcode == ARITH || opcode == ARITH_IMM) &&  (fn3 ==SLTU_fn3 || fn3 ==SLT_fn3)));//SUB instruction
            alu_inputs.arith <= alu_rs1[XLEN-1] & ib.data_out.instruction[30];//shift in bit
            alu_inputs.left_shift <= ~fn3[2];
            alu_inputs.shifter_in <= fn3[2] ? rf_decode.rs1 : left_shift_in;
            alu_inputs.sltu <= fn3[0];//(fn3 ==SLTU_fn3);
            alu_inputs.op <= alu_op;
        end
     end
    //----------------------------------------------------------------------------------

    //----------------------------------------------------------------------------------
    //Load Store unit inputs
    //----------------------------------------------------------------------------------
    assign ls_ex.new_request_dec = issue_ls;
    
    assign ls_offset = 32'(signed'(opcode[5] ? {ib.data_out.instruction[31:25], ib.data_out.instruction[11:7]} : ib.data_out.instruction[31:20]));
    
    assign ls_inputs.virtual_address = rf_decode.rs1 + ls_offset;//rf_decode.rs1;
    assign ls_inputs.rs2 = rf_decode.rs2;
    assign ls_inputs.pc = ib.data_out.pc;
    assign ls_inputs.fn3 = ls_inputs.is_amo ? LS_W_fn3 : fn3;
    //assign ls_inputs.imm = opcode[5] ? {ib.data_out.instruction[31:25], ib.data_out.instruction[11:7]} : ib.data_out.instruction[31:20];
    assign ls_inputs.amo = ib.data_out.instruction[31:27];
    assign ls_inputs.is_amo = (opcode == AMO);
    assign ls_inputs.load= (opcode == LOAD) || ((opcode == AMO) && (ls_inputs.amo != AMO_SC)); //LR and AMO_ops perform a read operation as well
    assign ls_inputs.store=(opcode == STORE);
    assign ls_inputs.load_store_forward =  (opcode == STORE) && rf_decode.rs2_conflict; 
        
    always_ff @(posedge clk) begin
        if (issue_ls)
            load_rd <= future_rd_addr;
    end

    always_ff @(posedge clk) begin
        if (rst)
            last_ls_request_was_load <= 0;
        else if (issue_ls)
            last_ls_request_was_load <=  ls_inputs.load;
        else if (advance && uses_rd && (load_rd == future_rd_addr))
            last_ls_request_was_load <=0; 
    end    
        
    //----------------------------------------------------------------------------------
    
    //----------------------------------------------------------------------------------
    //Branch unit inputs
    //----------------------------------------------------------------------------------
    assign branch_ex.new_request_dec = issue_branch;
    assign branch_inputs.rs1 = rf_decode.rs1;
    assign branch_inputs.rs2 = rf_decode.rs2;
    assign branch_inputs.fn3 = fn3;
    assign branch_inputs.dec_pc = ib.data_out.pc;
    assign branch_inputs.use_signed = !((fn3 == BLTU_fn3) || (fn3 == BGEU_fn3));
     
    assign branch_inputs.prediction = ib.data_out.prediction;
    
    assign branch_inputs.jal = opcode[3];//(opcode == JAL);
    assign branch_inputs.jalr = ~opcode[3] & opcode[2];//(opcode == JALR);
    assign branch_inputs.branch_compare = (opcode[3:2] == 0) ;//(opcode == BRANCH);
    assign branch_inputs.jal_imm = {ib.data_out.instruction[31], ib.data_out.instruction[19:12], ib.data_out.instruction[20], ib.data_out.instruction[30:21]};
    assign branch_inputs.jalr_imm = ib.data_out.instruction[31:20];
    assign branch_inputs.br_imm = {ib.data_out.instruction[31], ib.data_out.instruction[7], ib.data_out.instruction[30:25], ib.data_out.instruction[11:8]};    
    //----------------------------------------------------------------------------------
    
    //----------------------------------------------------------------------------------
    //CSR unit inputs
    //----------------------------------------------------------------------------------
    assign csr_ex.new_request_dec = issue_csr;
    always_ff @(posedge clk) begin
        if (issue_csr) begin
            csr_inputs.rs1 <= csr_imm_op ? {27'b0, rs1} : rf_decode.rs1; //immediate mode or rs1 reg
            csr_inputs.csr_addr <= ib.data_out.instruction[31:20];
            csr_inputs.csr_op <= fn3;
        end
    end
    //----------------------------------------------------------------------------------
    
    
    //----------------------------------------------------------------------------------
    //Mul Div unit inputs
    //----------------------------------------------------------------------------------
    assign mul_ex.new_request_dec = issue_mul;
    assign mul_inputs.rs1 = rf_decode.rs1;
    assign mul_inputs.rs2 = rf_decode.rs2;
    assign mul_inputs.op = fn3[1:0];

    //If a subsequent div request uses the same inputs then
    //don't rerun div operation
    always_ff @(posedge clk) begin
        if (issue_div) begin
            prev_div_rs1 <= rs1;
            prev_div_rs2 <= rs2;     
        end
    end
    
    always_ff @(posedge clk) begin
        if (rst)
            prev_div_result_valid <= 0;
        else if (issue_div)
            prev_div_result_valid <=1;
        else if (advance && uses_rd && (prev_div_rs1 == future_rd_addr || prev_div_rs2 == future_rd_addr))
            prev_div_result_valid <=0;
    end    
        
    assign div_ex.new_request_dec = issue_div;
    assign div_inputs.rs1 = rf_decode.rs1;
    assign div_inputs.rs2 = rf_decode.rs2;
    assign div_inputs.op = fn3[1:0];
    assign div_inputs.reuse_result = prev_div_result_valid && (prev_div_rs1 == rs1) && (prev_div_rs2 == rs2);
    assign div_inputs.overflow =~fn3[0] && (rf_decode.rs1[31] && rf_decode.rs1[30:0] == 0) && (rf_decode.rs2 == '1);
    assign div_inputs.div_zero = (rf_decode.rs2 == 0);
    
    
    
    //----------------------------------------------------------------------------------
    //Bit unit inputs
    //----------------------------------------------------------------------------------
    assign bit_ex.new_request_dec = issue_bit;

    always_ff @(posedge clk) begin
        if (issue_bit) begin
            bit_inputs.rs1 <= rf_decode.rs1;
            bit_inputs.fn3 <= fn3;
        end
    end
    
    assign fn3_dec = fn3;
    //----------------------------------------------------------------------------------

    
    
    //----------------------------------------------------------------------------------    
    always_ff @(posedge clk) begin
        if(rst) begin
            branch_ex.new_request <= 0;
            alu_ex.new_request <= 0;
            ls_ex.new_request <= 0;
            csr_ex.new_request <= 0;
            mul_ex.new_request <= 0;
            div_ex.new_request <= 0;
            bit_ex.new_request <= 0;
        end else begin
            branch_ex.new_request <= issue_branch;
            alu_ex.new_request <= issue_alu;
            ls_ex.new_request <= issue_ls;
            csr_ex.new_request <= issue_csr;
            mul_ex.new_request <= issue_mul;
            div_ex.new_request <= issue_div; 
            bit_ex.new_request <= issue_bit; 
        end
    end
    
endmodule
