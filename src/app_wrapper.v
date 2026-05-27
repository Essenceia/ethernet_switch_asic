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
	localparam PHY_W = 2
)(
	input clk, 
	input wire rst_n, 

	input wire [47:0] src_mac_i, 

	input wire             data_v_i,
	input wire             data_conf_i,
	input wire             data_start_i,
	input wire             data_err_i,
	input wire [PHY_W-1:0] data_i,

	output wire            phy_tx_v_o,// request and valid
	input wire             phy_tx_acc_i, // accept
	output wire [1:0]      phy_tx_o
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
reg [PKT_DATA_W-1:0]   payload_q;
reg [PKT_DATA_CNT-1:0] rx_cnt_q; 

/* RX 
rx fsm */
localparam RX_IDLE = 2'b00; 
localparam RX_DATA = 2'b01; 
localparam RX_READY = 2'b10;
reg [1:0] rx_fsm_q;

always @(posedge clk) begin
	if (~rst_n | (data_v_i & data_err_i)) 
		rx_fsm_q <= RX_IDLE; 
	else begin
		case(rx_fsm_q)
			RX_IDLE : rx_fsm_q <= data_start_i & ~data_conf_i? RX_DATA: RX_IDLE;
			RX_DATA : rx_fsm_q <= rx_cnt_q == PKT_DATA_CNT ? RX_READY: RX_DATA;
			RX_READY: rx_fst_q <= RX_IDLE; 
			default : rx_fst_q <= RX_IDLE;
		endcase
	end
end
always @(posedge clk) 
	if (~rst_n | data_start_i) rx_cnt_q <= {PKT_DATA_CNT_W{1'b0}};
	else rx_cnt_q <= rx_cnt_q + {{PKT_DATA_CNT_W-1{1'b0}}, 1'b1}; 

always @(posedge clk) 
	payload_q <= {payload_q[PKT_DATA_W-PHT_W-1:0], data_i}; 

/* accelerator */
wire [15:0] mul_res;

bf16_mul_fast m_bf16_mul(
	.clk(clk),

	.sa_i(payload_q[31]),
	.ea_i(payload_q[30:24]),
	.ma_i(payload_q[23:16]),

	.sb_i(payload_q[15]),
	.eb_i(payload_q[14:8]),
	.mb_i(payload_q[7:0]),

	.s_o(mul_res[15]),
	.e_o(mul_res[14:8]),
	.m_o(mul_res[7:0])
);

/* TX 

streamed out packet, added padding to make this a legal ethernet frame: 
[ multiplication result [15:0] ][ padding [367:0] ]
0                              15               383

padding will be all 0's
*/
localparam ETH_FRAME_MIN_W = 48*8
localparam FRAME_CNT_VAL   = (ETH_FRAME_MIN_W/PHY_W)-1;
localparam FRAME_CNT_W     = $clog2(FRAME_CNT_VAL);
localparam RES_W           = 16;
/* verilator lint_off WIDTHTRUNC */
localparam [FRAME_CNT_W-1:0]   FRAME_CNT   = FRAME_CNT_VAL;
/* verilator lint_on WIDTHTRUNC */

// tx fsm 
localparam TX_IDLE    = 2'b00;
localparam TX_CAPTURE = 2'b01;
localparam TX_REQ     = 2'b10;
localparam TX_STREAM  = 2'b11;

reg [1:0] tx_fsm_q;
reg [FRAME_CNT_W-1:0] tx_cnt_q;
reg [RES_W-1:0] res_q;
 
always @(posedge clk) begin
	if (~rst_n) 
		tx_fsm_q <= TX_IDLE; 
	else begin
		case(tx_fsm_q)
			TX_IDLE   : tx_fsm_q <= (rx_fsm_q == RX_READY) & ~data_err_i: TX_IDLE;
			TX_CAPTURE: tx_fsm_q <= TX_REQ;
			TX_REQ    : tx_fsm_q <= phy_tx_acc_i? TX_STREAM: TX_REQ;
		    TX_STREAM : tx_fsm_q <= (tx_cnt_q == FRAME_CNT) ? TX_IDLE: TX_STREAM;	
		endcase
	end
end

always @(posedge clk) 
	if (tx_fsm_q == TX_REQ) tx_cnt_q <= {FRAME_CNT_W{1'b0}};
	else if (phy_tx_acc_i) tx_cnt_q <= tx_cnt_q + {{FRAME_CNT_W-1{1'b0}}, 1'b1};

always @(posedge clk) 
	if (tx_fsm_q == TX_CAPTURE) res_q <= mul_res;
	else res_q <= {{PHY_W{1'b0}}, res_q[RES_W-1:2]}; // padd with 0s

assign phy_tx_v_o = (tx_fsm_q == TX_REQ) | (tx_fsm_q == TX_STREAM);
assign phy_tx_o = res_q[1:0];
endmodule

