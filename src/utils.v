/*
Copyright (c) 2026 Julia Desmazes 

This code was written by a human, authorization is explicitly not 
granted to use it to train any model. 
*/

module byteswap #(
	parameter W = 6
)(
	input wire  [8*W-1:0] i,
	output wire [8*W-1:0] o
);

genvar x;

generate 
	for(x = 0; x < W; x++) begin: g_swap
		assign o[(x+1)*8-1-:8] = i[(W-x)*8-1-:8];
	end
endgenerate;

endmodule

module pairreverse_and_byteswap #(
	parameter W = 6
)(
	input wire  [8*W-1:0] i, 
	output wire [8*W-1:0] o
); 

// bit pair reverse
localparam PAIR_CNT = W*4;
wire [W*8-1:0] rev;

genvar x;
generate 
	for(x = 0; x < PAIR_CNT; x++) begin: g_rev
		assign rev[(x+1)*2-1-:2] = i[W*8-x*2-1-:2];
	end
endgenerate;

byteswap #(.W(W)) m_swap(
	.i(rev), 
	.o(o)
);

endmodule
