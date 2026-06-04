/*
Copyright (c) 2026 Julia Desmazes, all rights reserved.  

This code was written by a human, authorization is explicitly not 
granted to use it to train any model. 
*/

`default_nettype none

/* store MAC configurations, updated by offload CPU
configs: 
- TX clk phase
- VLAN ID (12 bits)
- Device MAC address (48 bits)

By default these configs will be set based 
on the module parameters and reset to default
on each sync reset.
*/
`define BYTE_PAD(x) (((x + 7)/8)*8)
module mac_conf #(
	localparam VID_W       = 12,
	localparam VID_PAD_W   = `BYTE_PAD(VID_W),
	localparam MAC_W       = 48,
	localparam PHASE_W     = 1,	
	localparam PHASE_PAD_W = `BYTE_PAD(PHASE_W),	
	parameter PHY_W = 2,
	parameter [VID_W-1:0] DEFAULT_VID = 12'hDAD,
	parameter [MAC_W-1:0] DEFAULT_MAC = 48'h0090CF00BEEF // nortel beef 
)
(
	input wire clk, 
	input wire rst_n,

	input wire             default_tx_phase_i, 
	
	input wire             data_v_i,
	input wire             data_conf_i,
	input wire             data_start_i,
	input wire             data_err_i,
	input wire [PHY_W-1:0] data_i,

	output wire             clk_phase_sel_o,
	output wire [VID_W-1:0] vid_o,
	output wire [MAC_W-1:0] mac_addr_o
);

/* Configuration packet types :

[ MAC address [47:0] ][ VID [15:0] ][ phase [7:0] ][ padding ]
0                    47            63             71       383 
 
*/
localparam PKT_DATA_W       = (MAC_W + VID_PAD_W + PHASE_PAD_W);
localparam PKT_DATA_CNT_VAL = (PKT_DATA_W/PHY_W) - 1;
localparam PKT_DATA_CNT_W   = $clog2(PKT_DATA_CNT_VAL);
/* verilator lint_off WIDTHTRUNC */
localparam [PKT_DATA_CNT_W-1:0] PKT_DATA_CNT = PKT_DATA_CNT_VAL;
/* verilator lint_on WIDTHTRUNC */

// fsm 
localparam IDLE  = 1'b0;
localparam CONF  = 1'b1;

reg fsm_q;
reg [PKT_DATA_CNT_W-1:0] cnt_q;

/* fsm 
assuming errors will show up before payload
can't handle errors if they occure after header
given we don't have the area to do config store and forward */
always @(posedge clk) begin 
	if (~rst_n) 
		fsm_q <= IDLE; 
	else begin
		case(fsm_q)
			IDLE: fsm_q <=  data_start_i & ~data_err_i & data_conf_i ? CONF: IDLE; 
			CONF: fsm_q <=  cnt_q == PKT_DATA_CNT ? IDLE: CONF;
		endcase
	end
end

always @(posedge clk) 
	if (fsm_q == IDLE) cnt_q <= {PKT_DATA_CNT_W{1'b0}};
	else cnt_q <= cnt_q + {{PKT_DATA_CNT_W-1{1'b0}}, 1'b1};

localparam BUF_W = PKT_DATA_W;

reg  [BUF_W-1:0] buff_q;
wire [BUF_W-1:0] swap_buff;
wire [BUF_W-1:0] swap_rst_conf;
wire [BUF_W-1:0] rst_conf;

assign rst_conf = { DEFAULT_MAC, {4{1'bx}}, DEFAULT_VID , {7{1'bx}}, default_tx_phase_i}; 
byteswap #(.W(BUF_W/8)) m_swap_rst_conf(.i(rst_conf), .o(swap_rst_conf));

always @(posedge clk) 
	if (~rst_n) 
		buff_q <= swap_rst_conf;
	else if (fsm_q == CONF)
		buff_q <= {data_i, buff_q[BUF_W-1:PHY_W]};
	
byteswap #(.W(BUF_W/8)) m_buff_swap(.i(buff_q), .o(swap_buff));

assign mac_addr_o      = swap_buff[BUF_W-1-:MAC_W];
assign vid_o           = swap_buff[BUF_W-MAC_W-(VID_PAD_W-VID_W)-1-:VID_W];
assign clk_phase_sel_o = swap_buff[0];

endmodule
