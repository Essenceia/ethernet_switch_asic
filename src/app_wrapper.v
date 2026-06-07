/*
Copyright (c) 2026 Julia Desmazes 

This code was written by a human, authorization is explicitly not 
granted to use it to train any model. 
*/

`default_nettype none

/* 
Application example: floating point multiplication
Since data without the proper dst address and ethertype
if filtered out we are not adding a magic number check.
*/
module app_wrapper #(
	parameter PHY_W = 2,
	localparam MAC_W = 48 
)(
	input wire clk, 
	input wire rst_n, 

	input wire             data_v_i,
	input wire             data_conf_i,
	input wire             data_start_i,
	input wire             data_err_i,
	input wire [PHY_W-1:0] data_i,
	input wire [MAC_W-1:0] data_src_mac_i, 

	output wire             mac_tx_v_o,// request and valid
	output wire             mac_tx_last_o,
	input wire              mac_tx_acc_i, // accept
	output wire [PHY_W-1:0] mac_tx_o,
	output wire [MAC_W-1:0] mac_tx_dst_mac_o// guarantied to not change until packet header has finished sending
);
localparam PKT_DATA_W       = 32;
localparam PKT_DATA_CNT_VAL = (PKT_DATA_W/PHY_W) - 1;
localparam PKT_DATA_CNT_W   = $clog2(PKT_DATA_CNT_VAL);
/* verilator lint_off WIDTHTRUNC */
localparam [PKT_DATA_CNT_W-1:0] PKT_DATA_CNT = PKT_DATA_CNT_VAL;
/* verilator lint_on WIDTHTRUNC */

/* Ethernet frame payload body : 
[ multiplicacant (A) [15:0] ][ multiplier (B) [15:0] ][ padding [351:0] ]
0                           15                       31               383
*/
reg  [PKT_DATA_W-1:0]     payload_q;
wire [PKT_DATA_W-1:0]     swap_payload;
reg  [PKT_DATA_CNT_W-1:0] rx_cnt_q; 

/* RX 
rx fsm */
localparam RX_IDLE  = 2'b00; 
localparam RX_DATA  = 2'b01; 
localparam RX_READY = 2'b10;
reg [1:0] rx_fsm_q;

always @(posedge clk) begin
	if (~rst_n | (data_v_i & data_err_i)) 
		rx_fsm_q <= RX_IDLE; 
	else begin
		case(rx_fsm_q)
			RX_IDLE : rx_fsm_q <= data_start_i & ~data_conf_i? RX_DATA: RX_IDLE;
			RX_DATA : rx_fsm_q <= rx_cnt_q == PKT_DATA_CNT ? RX_READY: RX_DATA;
			RX_READY: rx_fsm_q <= RX_IDLE; 
			default : rx_fsm_q <= RX_IDLE;
		endcase
	end
end
always @(posedge clk) 
	if (~rst_n | data_start_i) rx_cnt_q <= {PKT_DATA_CNT_W{1'b0}};
	else rx_cnt_q <= rx_cnt_q + {{PKT_DATA_CNT_W-1{1'b0}}, 1'b1}; 

always @(posedge clk) 
	if (rx_fsm_q == RX_DATA) payload_q <= {data_i , payload_q[PKT_DATA_W-1:PHY_W]}; 

byteswap #(.W(PKT_DATA_W/8)) m_swap_payload(.i(payload_q), .o(swap_payload));

/* accelerator */
wire [15:0] mul_res;

`ifdef COCOTB
/* Replacing floating point model with unsigned integer math 
 * for cocotb since we don't have a good golden model 
 * in python for bf16, bf16 implementations used a clamped down
 * version of f32 which would result in the accumulation of 
 * the different precision rounding error though the network.
 * Floating point math correctness in this ASIC will be thoughly 
 * validated during emulation on the FPGA with the actual 
 * requests and results sent over ethernet. This will likely 
 * be about as fast as simulating it anyways. */
wire [15:0] mul_raw_carry, mul_raw;
reg  [15:0] mul_res_q;
assign {mul_raw_carry, mul_raw} = swap_payload[31:16]* swap_payload[15:0]; 
// clamping
always @(posedge clk) 
	mul_res_q <= |mul_raw_carry ? {16{1'b1}} : mul_raw; 

assign mul_res = mul_res_q; 
 
`else

bf16_mul_fast m_bf16_mul(
	.clk(clk),

	.sa_i(swap_payload[31]),
	.ea_i(swap_payload[30:23]),
	.ma_i(swap_payload[22:16]),

	.sb_i(swap_payload[15]),
	.eb_i(swap_payload[14:7]),
	.mb_i(swap_payload[6:0]),

	.s_o(mul_res[15]),
	.e_o(mul_res[14:7]),
	.m_o(mul_res[6:0])
);

`endif // COCOTB

/* TX 

streamed out packet, added padding to make this a legal ethernet frame: 
[ multiplication result [15:0] ][ padding [367:0] ]
0                              15               383

padding will be all 0's
*/
localparam ETH_FRAME_MIN_W = 46*8;
localparam FRAME_CNT_VAL   = (ETH_FRAME_MIN_W/PHY_W)-1;
localparam FRAME_CNT_W     = $clog2(FRAME_CNT_VAL);
localparam RES_W           = 16;
/* verilator lint_off WIDTHTRUNC */
localparam [FRAME_CNT_W-1:0]   FRAME_CNT       = FRAME_CNT_VAL;
localparam [FRAME_CNT_W-1:0]   FRAME_CNT_MIN_1 = FRAME_CNT_VAL - 1;
/* verilator lint_on WIDTHTRUNC */

// tx fsm 
localparam TX_IDLE    = 2'b00;
localparam TX_CAPTURE = 2'b01;
localparam TX_REQ     = 2'b10;
localparam TX_STREAM  = 2'b11;

reg  [1:0] tx_fsm_q;
reg  [FRAME_CNT_W-1:0] tx_cnt_q;
wire [RES_W-1:0] swap_mul_res;
reg  [RES_W-1:0] res_q;
reg              mac_tx_v_q;
reg              mac_tx_last_q; 
 
always @(posedge clk) begin
	if (~rst_n) 
		tx_fsm_q <= TX_IDLE; 
	else begin
		case(tx_fsm_q)
			TX_IDLE   : tx_fsm_q <= (rx_fsm_q == RX_READY) & ~data_err_i? TX_CAPTURE: TX_IDLE;
			TX_CAPTURE: tx_fsm_q <= TX_REQ;
			TX_REQ    : tx_fsm_q <= mac_tx_acc_i? TX_STREAM: TX_REQ;
		    TX_STREAM : tx_fsm_q <= (tx_cnt_q == FRAME_CNT) ? TX_IDLE: TX_STREAM;	
		endcase
	end
end

// floppe early versions for timing, signals are on the critical path
always @(posedge clk) begin
	mac_tx_v_q <= (tx_fsm_q == TX_CAPTURE) | (tx_fsm_q == TX_REQ) |  ((tx_fsm_q == TX_STREAM) & (tx_cnt_q != FRAME_CNT));
	mac_tx_last_q <= (tx_fsm_q == TX_STREAM) & (tx_cnt_q == FRAME_CNT_MIN_1);
end

always @(posedge clk) 
	if (tx_fsm_q == TX_REQ) tx_cnt_q <= {FRAME_CNT_W{1'b0}};
	else if (mac_tx_acc_i) tx_cnt_q <= tx_cnt_q + {{FRAME_CNT_W-1{1'b0}}, 1'b1};

byteswap #(.W(RES_W/8)) m_swap_mul_res(.i(mul_res), .o(swap_mul_res));

always @(posedge clk) 
	if (tx_fsm_q == TX_CAPTURE) res_q <= swap_mul_res;
	else if (tx_fsm_q == TX_STREAM) res_q <= {{PHY_W{1'b0}}, res_q[RES_W-1:PHY_W]}; // padd with 0s

assign mac_tx_v_o       = mac_tx_v_q;
assign mac_tx_last_o    = mac_tx_last_q;
assign mac_tx_o         = res_q[PHY_W-1:0];
assign mac_tx_dst_mac_o = data_src_mac_i;

endmodule

