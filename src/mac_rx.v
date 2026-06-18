/*
Copyright (c) 2026 Julia Desmazes, all rights reserved.  

This code was written by a human, authorization is explicitly not 
granted to use it to train any model. 
*/

`default_nettype none

/* Switch mac rx, no filtering */
module mac_rx #(
	parameter PHY_W = 2
)(
	input wire clk, 
	input wire rst_n, 
 
	input wire              rx_v_i, 
	input wire [PHY_W-1:0]  rx_i, 
	input wire              rx_err_i,

	output wire             data_v_o, 
	output wire             data_err_o,
	output wire [PHY_W-1:0] data_o
); 
localparam SFD_W = 8; 
localparam [SFD_W-1:0] SFD = 8'b11010101; 

// fsm 
localparam IDLE       = 2'd0; 
localparam DETECT_SFD = 2'd1;
localparam FRAME      = 2'd2; 
 
reg [1:0] fsm_q;
reg       err_q; 

localparam BUF_W = 8;
reg  [BUF_W-1:PHY_W] buff_q;
wire [BUF_W-1:0]     buff;
wire [BUF_W-1:0]     swap_buff;
wire                 frame_start;

// fsm 
always @(posedge clk) begin
	if (~rst_n) 
		fsm_q <= IDLE; 
	else begin
		case(fsm_q)
			IDLE:       fsm_q <= rx_v_i ? DETECT_SFD : IDLE;
			DETECT_SFD: fsm_q <= frame_start ? FRAME: DETECT_SFD;
			FRAME:       fsm_q <= rx_v_i ? FRAME: IDLE;
			default:    fsm_q <= IDLE;  
		endcase	
	end
end

// stream from PHY is expected to be gappless
assign buff = {rx_i, buff_q[BUF_W-1:PHY_W]};

byteswap #(.W(BUF_W/8)) m_swap_buf(.i(buff), .o(swap_buff));

always @(posedge clk) 
	if (~rst_n) 
		buff_q <= {BUF_W-2{1'b0}};
	else
		buff_q <= buff[BUF_W-1:PHY_W];
 
// detect SFD
assign frame_start = swap_buff[SFD_W-1:0] == SFD; 

// sticky error 
always @(posedge clk) 
	if (fsm_q == IDLE) 
		err_q <= 1'b0; // IFG guaranties no back to back frames
	else 
		err_q <=  err_q | (rx_v_i & rx_err_i); 

assign data_v_o       = (fsm_q == FRAME);
assign data_o         = buff_q[BUF_W-1-:PHY_W];
assign data_err_o     = err_q;

endmodule
