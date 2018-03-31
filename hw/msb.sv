//(C) 2017 Eric Matthews, Lesley Shannon.  All rights reserved.
module msb
        (
        input logic [31:0] msb_input,
        output logic [4:0] msb
        );
    
    logic [2:0] sub_msb [3:0];
    logic [3:0] bit_found;    
          
    //Finds MSB for 4x 8-bit segments in parallel
    //Is smaller and faster than checking the full width sequentially (i.e. from 0 to 31)
    genvar i;
    generate
        for (i=0; i<4; i++) begin : bit_found_g
            assign bit_found[i] = |msb_input[(i+1)*8-1:i*8];
        end
    endgenerate    
    
    always_comb begin
		  for (int i=0; i<4; i=i+1) begin
        //foreach(sub_msb[i]) begin
            sub_msb[i] = 0;
            for (int j=1;j<8; j++) begin
                if (msb_input[(i*8)+j])
                    sub_msb[i] = j;
            end
        end
        
        if(bit_found[3]) msb = {2'b0,sub_msb[3]}+24;
        else if(bit_found[2]) msb = {2'b0,sub_msb[2]}+16;
        else if(bit_found[1]) msb = {1'b0,sub_msb[1]+8};
        else msb = {2'b0,sub_msb[0]};
        
    end
    
endmodule
