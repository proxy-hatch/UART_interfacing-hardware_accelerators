`timescale 1 ps / 1 ps

import riscv_config::*;
import riscv_types::*;
localparam RAM_FILE =  "";


module lab6 (
		input  wire  CLOCK_50,       //   clk.clk
		input  wire[3:0]  KEY  // reset.reset_n
	);

	wire    rst_controller_reset_out_reset;  

    avalon_interface m_avalon();
    bram_interface instruction_bram();
    bram_interface data_bram();
    
	auto_gen_jtag_uart_0 jtag_uart_0 (
		.clk            (CLOCK_50),                     //               clk.clk
		.rst_n          (~rst_controller_reset_out_reset), //             reset.reset_n
		.av_chipselect  (m_avalon.read | m_avalon.write),  // avalon_jtag_slave.chipselect
		.av_address     (m_avalon.addr[2]),     //                  .address
		.av_read_n      (~m_avalon.read),       //                  .read_n
		.av_readdata    (m_avalon.readdata),    //                  .readdata
		.av_write_n     (~m_avalon.write),      //                  .write_n
		.av_writedata   (m_avalon.writedata),   //                  .writedata
		.av_waitrequest (m_avalon.waitrequest), //                  .waitrequest
		.av_irq         ()                                     //               irq.irq
	);
    
        riscv processor (
        .clk                                 (CLOCK_50),                                               //                       clk.clk
        .rst(rst_controller_reset_out_reset),//rst_controller_reset_out_reset),
        .m_avalon(m_avalon),
        .instruction_bram(instruction_bram),
        .data_bram(data_bram)
    );
    
        //Instruction/Data RAM
    byte_en_BRAM #(.LINES(8192), .preload_file(RAM_FILE), .USE_PRELOAD_FILE(1)) inst_data_ram (
            .clk(CLOCK_50), 
            .addr_a(instruction_bram.addr[$clog2(8192)-1:0]), 
            .en_a(instruction_bram.en),
            .be_a(instruction_bram.be),
            .data_in_a(instruction_bram.data_in),
            .data_out_a(instruction_bram.data_out),
        
            .addr_b(data_bram.addr[$clog2(8192)-1:0]), 
            .en_b(data_bram.en),
            .be_b(data_bram.be),
            .data_in_b(data_bram.data_in),
            .data_out_b(data_bram.data_out)
        );

	altera_reset_controller #(
		.NUM_RESET_INPUTS          (1),
		.OUTPUT_RESET_SYNC_EDGES   ("deassert"),
		.SYNC_DEPTH                (2),
		.RESET_REQUEST_PRESENT     (0),
		.RESET_REQ_WAIT_TIME       (1),
		.MIN_RST_ASSERTION_TIME    (3),
		.RESET_REQ_EARLY_DSRT_TIME (1),
		.USE_RESET_REQUEST_IN0     (0),
		.USE_RESET_REQUEST_IN1     (0),
		.USE_RESET_REQUEST_IN2     (0),
		.USE_RESET_REQUEST_IN3     (0),
		.USE_RESET_REQUEST_IN4     (0),
		.USE_RESET_REQUEST_IN5     (0),
		.USE_RESET_REQUEST_IN6     (0),
		.USE_RESET_REQUEST_IN7     (0),
		.USE_RESET_REQUEST_IN8     (0),
		.USE_RESET_REQUEST_IN9     (0),
		.USE_RESET_REQUEST_IN10    (0),
		.USE_RESET_REQUEST_IN11    (0),
		.USE_RESET_REQUEST_IN12    (0),
		.USE_RESET_REQUEST_IN13    (0),
		.USE_RESET_REQUEST_IN14    (0),
		.USE_RESET_REQUEST_IN15    (0),
		.ADAPT_RESET_REQUEST       (0)
	) rst_controller (
		.reset_in0      (KEY[0]),                 // reset_in0.reset
		.clk            (CLOCK_50),                        //       clk.clk
		.reset_out      (rst_controller_reset_out_reset), // reset_out.reset
		.reset_req      (),                               // (terminated)
		.reset_req_in0  (1'b0),                           // (terminated)
		.reset_in1      (1'b0),                           // (terminated)
		.reset_req_in1  (1'b0),                           // (terminated)
		.reset_in2      (1'b0),                           // (terminated)
		.reset_req_in2  (1'b0),                           // (terminated)
		.reset_in3      (1'b0),                           // (terminated)
		.reset_req_in3  (1'b0),                           // (terminated)
		.reset_in4      (1'b0),                           // (terminated)
		.reset_req_in4  (1'b0),                           // (terminated)
		.reset_in5      (1'b0),                           // (terminated)
		.reset_req_in5  (1'b0),                           // (terminated)
		.reset_in6      (1'b0),                           // (terminated)
		.reset_req_in6  (1'b0),                           // (terminated)
		.reset_in7      (1'b0),                           // (terminated)
		.reset_req_in7  (1'b0),                           // (terminated)
		.reset_in8      (1'b0),                           // (terminated)
		.reset_req_in8  (1'b0),                           // (terminated)
		.reset_in9      (1'b0),                           // (terminated)
		.reset_req_in9  (1'b0),                           // (terminated)
		.reset_in10     (1'b0),                           // (terminated)
		.reset_req_in10 (1'b0),                           // (terminated)
		.reset_in11     (1'b0),                           // (terminated)
		.reset_req_in11 (1'b0),                           // (terminated)
		.reset_in12     (1'b0),                           // (terminated)
		.reset_req_in12 (1'b0),                           // (terminated)
		.reset_in13     (1'b0),                           // (terminated)
		.reset_req_in13 (1'b0),                           // (terminated)
		.reset_in14     (1'b0),                           // (terminated)
		.reset_req_in14 (1'b0),                           // (terminated)
		.reset_in15     (1'b0),                           // (terminated)
		.reset_req_in15 (1'b0)                            // (terminated)
	);

endmodule
