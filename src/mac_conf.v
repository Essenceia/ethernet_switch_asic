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
module mac_conf #(
	localparam VID_W = 12,
	localparam MAC_W = 48,
	parameter PHY_W = 2,
	parameter [VID_W-1:0] DEFAULT_VID = 12'hDAD,
	parameter [MAC_W-1:0] DEFAULT_MAC = 48'h0090CF00BEEF // nortel beef 
)
(
	input clk, 
	input rst_n,

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

[ MAC address [47:0] ][ VID [15:0] ][ phase [1:0] ][ padding ]
0                    47            63             65       383 
 
*/
localparam PKT_DATA_W       = MAC_W + VID_W + 1;
localparam PKT_DATA_CNT_VAL = (PKT_DATA_W/PHY_W) - 1;
localparam PKT_DATA_CNT_W   = $clog2(PKT_DATA_CNT_VAL);
/* verilator lint_off WIDTHTRUNC */
localparam [PKT_DATA_CNT_W-1:0] PKT_DATA_CNT = PKT_DATA_CNT_VAL;
/* verilator lint_on WIDTHTRUNC */

// fsm 
localparam IDLE  = 1'b0;
localparam CONF  = 1'b1;

reg [0:0] fsm_q;
reg [PKT_DATA_CNT_W-1:0] cnt_q;
reg [1:0]       phase_sel_q;// only bottom bit is used, making 2 bits wide to align with PHY_W
reg [MAC_W-1:0] mac_addr_q;
reg [VID_W-1:0] vid_q;

/* fsm 
assuming errors will show up before payload
can't handle errors if they occure after header
given we don't have the area to do config store and forward */
always @(posedge clk) begin 
	if (~rst_n) 
		fsm_q <= IDLE; 
	else begin
		case(fsm_q)
			IDLE: fsm_q <= data_v_i & data_start_i & ~data_err_i & data_conf_i ? CONF: IDLE; 
			CONF: fsm_q <=  cnt_q == PKT_DATA_CNT? IDLE: CONF;
		endcase
	end
end

always @(posedge clk) 
	if (fsm_q == IDLE) cnt_q <= {PKT_DATA_CNT_W{1'b0}};
	else cnt_q <= { {PKT_DATA_CNT_W-1{1'b0}}, 1'b1};

always @(posedge clk) 
	if (~rst_n) 
		{ mac_addr_q, vid_q, phase_sel_q} <= { DEFAULT_MAC, DEFAULT_VID ,1'b0, default_tx_phase_i};
	else if (fsm_q == CONF)
		{ mac_addr_q, vid_q, phase_sel_q} <= {mac_addr_q[MAC_W-3:0], vid_q, phase_sel_q, data_i };
		
assign clk_phase_sel_o = phase_sel_q[0];
assign mac_addr_o = mac_addr_q;
assign vid_o = vid_q;

endmodule
