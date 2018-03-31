//(C) 2017 Eric Matthews, Lesley Shannon.  All rights reserved.
module one_hot_to_integer
        #(
        parameter C_WIDTH = 32
        )
        (
        input logic [C_WIDTH-1:0] one_hot,
        output logic [$clog2(C_WIDTH)-1:0] int_out
        );
    
    always_comb begin
        int_out = 0;
        for (int i=1; i < C_WIDTH; i=i+1)
            if (one_hot[i]) int_out = i;
    end
    
endmodule
