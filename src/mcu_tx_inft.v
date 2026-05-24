/*
Copyright (c) 2026 Julia Desmazes, all rights reserved.

This code was written by a human, authorization is explicitly not
granted to use it to train any model.
*/

`default_nettype none

module mcu_tx_intf(
	input clk, 
	input rst_n, 

	// MCU -> MAC TX
	input wire [1:0]  mcu_tx_cmd_i,
	input wire [1:0]  mcu_tx_i,

	output wire       mac_tx_v_o,
	output wire       mac_tx_start_o,
	output wire [1:0] mac_tx_o,

	//config
	output wire [11:0] vid_o,
	output wire [47:0] mac_addr_o,
	output wire        clk_phase_sel_o
);
localparam TX_CMD_IDLE          = 2'b00;
localparam TX_CMD_DATA          = 2'b01;
localparam TX_CMD_CONF_PHASE    = 2'b10;
localparam TX_CMD_CONF_MAC_VID  = 2'b11;

reg prev_valid_q;

reg [1:0] mcu_tx_cmd_q;
reg [1:0] mcu_tx_q;

// flop incomming data
always @(posedge clk) begin
	mcu_tx_cmd_q <= mcu_tx_cmd_i;
	mcu_tx_q     <= mcu_tx_i;
end

always @(posedge clk) 
	tx_data_v_q <= mcu_tx_cmd_q == TX_CMD_DATA;

// to MAC TX
assign mac_tx_v_o     = mcu_tx_cmd_q == TX_CMD_DATA;
assign mac_tx_start_o = mac_tx_v_o & ~tx_data_v_q;
assign mac_tx_o       = mcu_tx_q;
 
// config
mac_conf m_mac_conf(
	.clk(clk), 
	.rst_n(rst_n),

	.conf_v_i(mcu_tx_cmd_q[1]),
	.conf_type_i(mcu_tx_cmd_q[0]),
	.conf_i(mcu_tx_q),

	.vid_o(vid_o),
	.mac_addr_o(mac_addr_o),
	.clk_phase_sel_o(clk_phase_sel_o)
);
endmodule
