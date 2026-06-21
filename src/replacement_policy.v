/*
Copyright (c) 2026 Julia Desmazes 

This code was written by a human, authorization is explicitly not 
granted to use it to train any model. 
*/

`default_nettype none

/* Oldest entry evicted */
module replacement_policy #(
	parameter TTNN_W = 4,
	localparam N = 4
)(
	input  wire [N*TTNN_W-1:0] ttnn_i, 
	output wire [N-1:0]        victime_o 
);
localparam IDX_W = $clog2(N);

/*  behold my ascii art: 

  ttnn3        ttnn2      ttnn1      ttnn0
	|      <     |          |    <     | 
	--------------          ------------
lvl0[1:0]  |          <          |
           -----------------------
lvl1                  |
                     tada
*/
wire [1:0] lvl0;
wire       lvl1;

wire [TTNN_W-1:0] ttnn_lvl0[1:0];
wire [IDX_W-1:0]  idx_lvl0[1:0];
wire [IDX_W-1:0]  idx_lvl1;

assign lvl0[1]      = ttnn_i[4*TTNN_W-1-:TTNN_W]< ttnn_i[3*TTNN_W-1-:TTNN_W];
assign ttnn_lvl0[1] = lvl0[1] ? ttnn_i[4*TTNN_W-1-:TTNN_W] : ttnn_i[3*TTNN_W-1-:TTNN_W];
assign idx_lvl0[1]  = lvl0[1] ? 2'd3 : 2'd2;

assign lvl0[0]      = ttnn_i[2*TTNN_W-1-:TTNN_W]< ttnn_i[1*TTNN_W-1-:TTNN_W];
assign ttnn_lvl0[0] = lvl0[0] ? ttnn_i[2*TTNN_W-1-:TTNN_W] : ttnn_i[1*TTNN_W-1-:TTNN_W];
assign idx_lvl0[0]  = lvl0[0] ? 2'd1 : 2'd0;

assign lvl1 = ttnn_lvl0[1] < ttnn_lvl0[0];
assign idx_lvl1 = lvl1 ? idx_lvl0[1] : idx_lvl0[0];

wire [IDX_W-1:0] debug_idx_lvl0_1, debug_idx_lvl0_0;
assign debug_idx_lvl0_1 = idx_lvl0[1];
assign debug_idx_lvl0_0 = idx_lvl0[0];

reg [N-1:0] victime;
always @(*) begin
	case(idx_lvl1) 
		2'd0: victime = 4'b0001;
		2'd1: victime = 4'b0010;
		2'd2: victime = 4'b0100;
		2'd3: victime = 4'b1000;
	endcase
end
assign victime_o = victime;

endmodule
