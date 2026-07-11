/*
Copyright (c) 2026 Julia Desmazes 

This code was written by a human, authorization is explicitly not 
granted to use it to train any model. 
*/

`default_nettype none

module coffeepot #(
	parameter PORT_CNT = 3,
	parameter PHY_W = 2,
	parameter HAS_TX_PHASE = 0
)(
    input  wire       clk,      
    input  wire       rst_n,

	input wire        tx_phase_i,
	
	input  wire [PORT_CNT-1:0]       phy_rx_v_i,    
	input  wire [PORT_CNT-1:0]       phy_rx_err_i,    
	input  wire [PORT_CNT*PHY_W-1:0] phy_rx_i, // data   

	output wire [PORT_CNT-1:0]       phy_tx_v_o,    
	output wire [PORT_CNT*PHY_W-1:0] phy_tx_o // data
);

// rst flop
reg rst_n_q; 
always @(posedge clk) 
	rst_n_q <= rst_n; 

// rx to mac rx
wire             rmii_rx_v[PORT_CNT-1:0];
wire             rmii_rx_err[PORT_CNT-1:0];
wire [PHY_W-1:0] rmii_rx[PORT_CNT-1:0];

wire             phy_rx_v[PORT_CNT-1:0];
wire             phy_rx_err[PORT_CNT-1:0];
wire [PHY_W-1:0] phy_rx[PORT_CNT-1:0];

wire             mac_rx_v[PORT_CNT-1:0];
wire [PHY_W-1:0] mac_rx[PORT_CNT-1:0];
// lookup to tx
wire             rmii_tx_v[PORT_CNT-1:0];
wire [PHY_W-1:0] rmii_tx[PORT_CNT-1:0];

wire             phy_tx_v[PORT_CNT-1:0];
wire [PHY_W-1:0] phy_tx[PORT_CNT-1:0];

// switch <-> mac tx
wire             mac_tx_v[PORT_CNT-1:0];
wire [PHY_W-1:0] mac_tx[PORT_CNT-1:0];
wire             mac_tx_last[PORT_CNT-1:0];
wire             mac_tx_acc[PORT_CNT-1:0];

genvar i; 

generate 
	for(i = 0; i < PORT_CNT; i=i+1) begin: g_port_data_assign
		assign phy_rx[i] = phy_rx_i[(i+1)*PHY_W-1-:PHY_W];
		assign phy_tx_o[(i+1)*PHY_W-1-:PHY_W] = phy_tx[i];
	end
endgenerate
assign phy_rx_v   = phy_rx_v_i; 
assign phy_rx_err = phy_rx_err_i;
assign phy_tx_v_o = phy_tx_v;

generate 
	for(i = 0; i < PORT_CNT; i=i+1) begin: g_channel
		rmii #(.HAS_TX_PHASE(HAS_TX_PHASE)) m_rmii(
			.clk(clk),
			.rst_n(rst_n_q),
			.clk_phase_sel_i(tx_phase_i),
			.phy_tx_v_o(phy_tx_v[i]),
			.phy_tx_o  (phy_tx[i]),
			.phy_rx_v_i  (phy_rx_v[i]),
			.phy_rx_i    (phy_rx[i]),
			.phy_rx_err_i(phy_rx_err[i]),
			.mac_rx_v_o  (rmii_rx_v[i]),
			.mac_rx_o    (rmii_rx[i]),
			.mac_rx_err_o(rmii_rx_err[i]),
			.mac_tx_v_i(rmii_tx_v[i]),
			.mac_tx_i  (rmii_tx[i])
		);

		mac_rx m_mac_rx(
			.clk(clk),
			.rst_n(rst_n_q),
			.rx_v_i(rmii_rx_v[i]),
			.rx_i(rmii_rx[i]),
			.rx_err_i(rmii_rx_err[i]),
			.data_v_o(mac_rx_v[i]),
			.data_o(mac_rx[i])
		);

		mac_tx m_mac_tx(
			.clk(clk),
			.rst_n(rst_n_q),
			.data_v_i(mac_tx_v[i]),
			.data_i(mac_tx[i]),
			.data_last_i(mac_tx_last[i]),
			.data_acc_o(mac_tx_acc[i]),
			.tx_v_o(rmii_tx_v[i]),
			.tx_o(rmii_tx[i])
		);

	end
endgenerate

switch m_switch(
	.clk(clk), 
	.rst_n(rst_n_q), 
	.mac_rx_v_i({mac_rx_v[2], mac_rx_v[1], mac_rx_v[0]}),
	.mac_rx_i({mac_rx[2], mac_rx[1], mac_rx[0]}),
	
	.mac_tx_v_o({mac_tx_v[2], mac_tx_v[1], mac_tx_v[0]}),
	.mac_tx_o({mac_tx[2], mac_tx[1], mac_tx[0]}),
	.mac_tx_last_o({mac_tx_last[2], mac_tx_last[1], mac_tx_last[0]}),
	
	.mac_tx_acc_i({mac_tx_acc[2], mac_tx_acc[1], mac_tx_acc[0]})
);
endmodule
