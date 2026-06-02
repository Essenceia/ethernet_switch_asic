/*
Copyright (c) 2026 Julia Desmazes, all rights reserved.  

This code was written by a human, authorization is explicitly not 
granted to use it to train any model. 
*/

`default_nettype none

/* 
RX MAC layer. Will filter out all unicast packets not meant for
this device and will forward starting from the payload and excluding
the FCS. 
*/ 
module mac_rx #(
	parameter PHY_W = 2,
	localparam MAC_W = 48,
	localparam VID_W = 12,
	 // 802a playpen ethertypes 
	parameter [15:0] APP_ETHTYPE  = 16'h88B5,
	parameter [15:0] CONF_ETHTYPE = 16'h88B6
)(
	input clk, 
	input wire rst_n, 

	input wire [MAC_W-1:0] phy_mac_i, 
	input wire [VID_W-1:0] vid_i,// vlan id
 
	input wire        rx_v_i, 
	input wire [1:0]  rx_i, 
	input wire        rx_err_i,

	// to accelerator wrapper
	output wire        data_v_o,
	output wire        data_conf_o,
	output wire        data_start_o,
	output wire        data_err_o,
	output wire [1:0]  data_o,
	output wire [MAC_W-1:0] data_src_mac_o 
); 
localparam ADDR_CNT_VAL = (MAC_W/PHY_W) - 1;
localparam ADDR_CNT_W   = $clog2(ADDR_CNT_VAL); 
/* verilator lint_off WIDTHTRUNC */
localparam [ADDR_CNT_W-1:0] ADDR_CNT = ADDR_CNT_VAL;
/* verilator lint_on WIDTHTRUNC */

localparam SFD_W = 8; 
localparam [SFD_W-1:0] SFD = 8'b11010101; 

localparam FRAME_TYPE_W       = 16;
localparam FRAME_TYPE_CNT_VAL = (FRAME_TYPE_W/PHY_W) - 1;
localparam FRAME_TYPE_CNT_W   = $clog2(FRAME_TYPE_CNT_VAL);
/* verilator lint_off WIDTHTRUNC */
localparam [FRAME_TYPE_CNT_W-1:0] FRAME_TYPE_CNT = FRAME_TYPE_CNT_VAL;
/* verilator lint_on WIDTHTRUNC */

localparam [FRAME_TYPE_W-1:0] TYPE_VLAN = 16'h8100;

// FCS 
localparam FCS_W = 32; 

localparam DELAY_DEPTH = (FCS_W /PHY_W) + 1;

// fsm 
localparam IDLE       = 4'd0; 
localparam DETECT_SFD = 4'd1;
localparam DST_MAC    = 4'd2;
localparam SRC_MAC    = 4'd3;
localparam PKT_TYPE   = 4'd4;
localparam VLAN       = 4'd5;
localparam BODY       = 4'd6; 

localparam ERR        = 4'd7; 
 
reg [3:0] fsm_q;

reg err_q; 
reg fwd_q; // forward packet to higher level, not filted out

wire ethtype_match;
wire pkt_app;
wire pkt_conf;
reg  pkt_conf_q;

localparam BUF_W = MAC_W; // max(MAC_W,SFD_W,FCS_W)

reg  [BUF_W-1:PHY_W] buff_q;
wire [BUF_W-1:0] buff;
wire [BUF_W-1:0] swap_buff;
wire frame_start;

localparam CNT_W = ADDR_CNT_W; // $max(ADDR_CNT_W, FRAME_TYPE_CNT);
reg  [CNT_W-1:0] cnt_q; // shared counter 

reg [MAC_W-1:0] src_mac_q;
wire            dst_addr_match; 

wire            is_type;
wire            type_vlan; 
wire            vid_match;
  
wire [FCS_W-1:0] pkt_fcs;
wire             fcs_err; 
wire eof; 

// fsm 
always @(posedge clk) begin
	if (~rst_n) 
		fsm_q <= IDLE; 
	else begin
		// detect mac gap 
		if (rx_v_i & rx_err_i) begin
			fsm_q <= ERR;
		end else begin
			case(fsm_q)
				ERR:        fsm_q <= IDLE; 
				IDLE:       fsm_q <= rx_v_i ? DETECT_SFD : IDLE;
				DETECT_SFD: fsm_q <= frame_start ? DST_MAC: DETECT_SFD;
				DST_MAC:    fsm_q <= cnt_q[ADDR_CNT_W-1:0] == ADDR_CNT ? SRC_MAC: DST_MAC; 
				SRC_MAC:    fsm_q <= cnt_q[ADDR_CNT_W-1:0] == ADDR_CNT ? PKT_TYPE: SRC_MAC;
				PKT_TYPE:   fsm_q <= cnt_q[FRAME_TYPE_CNT_W-1:0] == FRAME_TYPE_CNT ? (type_vlan? VLAN: BODY):PKT_TYPE;
				VLAN:       fsm_q <= cnt_q[FRAME_TYPE_CNT_W-1:0] == FRAME_TYPE_CNT ? BODY: VLAN; 
				BODY:       fsm_q <= rx_v_i ? BODY: IDLE; 
				default:    fsm_q <= IDLE; 
			endcase	
		end
	end
end

assign eof = (fsm_q == BODY) & ~ rx_v_i;

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

// filter out packets that don't match our MAC address (or multicast)
always @(posedge clk)
	if ((frame_start & fsm_q == DETECT_SFD) 
       | (((fsm_q == SRC_MAC) | (fsm_q == DST_MAC)) & cnt_q[ADDR_CNT_W-1:0] == ADDR_CNT) 
       | (((fsm_q == PKT_TYPE) | (fsm_q == VLAN)) & cnt_q[FRAME_TYPE_CNT_W-1:0] == FRAME_TYPE_CNT)) 
		cnt_q <= {CNT_W{1'b0}};
	else
		cnt_q <= cnt_q + {{CNT_W-1{1'b0}}, 1'b1};

assign dst_addr_match = phy_mac_i == swap_buff;
assign type_vlan = swap_buff[FRAME_TYPE_W-1:0] == TYPE_VLAN; 
assign vid_match = swap_buff[VID_W-1:0] == vid_i;

assign is_type = (cnt_q[FRAME_TYPE_CNT_W-1:0] == FRAME_TYPE_CNT) & (((fsm_q == PKT_TYPE) & ~type_vlan) 
				 | (fsm_q == VLAN)); 

// ethertype filtering
assign pkt_conf = swap_buff[FRAME_TYPE_W-1:0] == CONF_ETHTYPE;
assign pkt_app = swap_buff[FRAME_TYPE_W-1:0] == APP_ETHTYPE;

assign ethtype_match = (pkt_app | pkt_conf);

always @(posedge clk) 
	if (~rst_n) 
		pkt_conf_q <= 1'b0;
	else if (is_type) 
		pkt_conf_q <= pkt_conf;

// forward 
always @(posedge clk) 
	if ((fsm_q == DST_MAC) & (cnt_q[ADDR_CNT_W-1:0] == ADDR_CNT)) 
		fwd_q       <= dst_addr_match;
	else if ((fsm_q == VLAN) & (cnt_q[FRAME_TYPE_CNT_W-1:0] == FRAME_TYPE_CNT))
		fwd_q <= fwd_q & vid_match;
	else if (is_type)
		fwd_q <= fwd_q & ethtype_match;

// src mac capture 
always @(posedge clk) 
	if ((fsm_q == SRC_MAC) & (cnt_q[ADDR_CNT_W-1:0] == ADDR_CNT))
		src_mac_q <= swap_buff[MAC_W-1:0];
 
// sticky error 
always @(posedge clk) 
	if (fsm_q == IDLE) 
		err_q <= 1'b0; // IFG guaranties no back to back frames
	else 
		err_q <=  err_q | (rx_v_i & rx_err_i) | fcs_err; 

// FCS 
crc_8 m_fcs(
	.clk(clk),
	.crc_rst_i(fsm_q == IDLE),
	.data_i(buff[BUF_W-1-:8]),
	.crc_en_i((fsm_q != DETECT_SFD) & (cnt_q[1:0] == 2'b11)),
	.crc_o(pkt_fcs)
);
assign fcs_err = eof & |(pkt_fcs);// end of packet, check fcs

// data buffer, excluding the FCS without keeping track of
// the data width for portability
reg [DELAY_DEPTH-1:0] delay_data_v_q; 
reg [DELAY_DEPTH-1:0] delay_data_start_q; 

always @(posedge clk)
	if (~rst_n | eof)
		delay_data_v_q <= {DELAY_DEPTH{1'b0}};
	else
		delay_data_v_q <= {delay_data_v_q[DELAY_DEPTH-2:0], fsm_q == BODY & fwd_q};

always @(posedge clk) 
	delay_data_start_q <= {delay_data_start_q[DELAY_DEPTH-2:0], is_type & ethtype_match & fwd_q};	

assign data_v_o       = delay_data_v_q[DELAY_DEPTH-1];
assign data_conf_o    = pkt_conf_q; 
assign data_start_o   = delay_data_start_q[DELAY_DEPTH-1]; 
assign data_err_o     = err_q;
assign data_o         = buff_q[FCS_W+1:FCS_W];
assign data_src_mac_o = src_mac_q;

`ifdef FORMEL 

`endif
endmodule
