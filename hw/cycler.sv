//(C) 2017 Eric Matthews, Lesley Shannon.  All rights reserved.
module  cycler
        #(
        parameter C_WIDTH = 2
        )
        (
        input logic clk,
        input logic rst,
        input logic en,
        output logic [C_WIDTH - 1: 0] one_hot
        );

    generate
        if (C_WIDTH == 1) begin
            assign one_hot = 1'b1;
        end
        else begin
            always_ff @ (posedge clk) begin
                if (rst) begin
                    one_hot[C_WIDTH-1:1] <= '0;
                    one_hot[0] <= 1'b1;
                end
                else if (en) begin
                    one_hot[C_WIDTH-1:1] <= one_hot[C_WIDTH-2:0];
                    one_hot[0] <= one_hot[C_WIDTH-1];
                end
            end
        end
    endgenerate
   
endmodule
