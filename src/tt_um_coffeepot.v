/*
Copyright (c) 2026 Julia Desmazes 

This code was written by a human, authorization is explicitly not 
granted to use it to train any model. 
*/

`default_nettype none

module tt_um_coffeepot #(
	localparam PORT_CNT = 3,
	localparam PHY_W = 2
)(
	input  wire [7:0] ui_in,    
    output wire [7:0] uo_out,   
    input  wire [7:0] uio_in,   
    output wire [7:0] uio_out,  
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);
wire [7:5] uio_in_unused;
wire       ena_unused; 
// IO
assign uio_oe       = 8'b11100000;
assign uo_out[4:3]  = 2'd0;
assign uio_out[4:0] = 5'd0;

assign uio_in_unused = uio_in[7:5];
assign ena_unused    = ena; 

// rst flop
reg rst_n_q; 
always @(posedge clk) 
	rst_n_q <= rst_n; 

// tx phase
wire tx_phase;
assign tx_phase = uio_in[4];

// rx to mac rx
wire             rmii_rx_v[PORT_CNT-1:0];
wire             rmii_rx_err[PORT_CNT-1:0];
wire [PHY_W-1:0] rmii_rx[PORT_CNT-1:0];

wire             phy_rx_v[PORT_CNT-1:0];
wire             phy_rx_err[PORT_CNT-1:0];
wire [PHY_W-1:0] phy_rx[PORT_CNT-1:0];

wire             mac_rx_v[PORT_CNT-1:0];
wire             mac_rx_start[PORT_CNT-1:0];
wire [PHY_W-1:0] mac_rx[PORT_CNT-1:0];
// RX0
assign phy_rx[0][0]  = ui_in[0];
assign phy_rx[0][1]  = ui_in[1];
assign phy_rx_v[0]   = ui_in[2];
assign phy_rx_err[0] = ui_in[3];  
// RX1
assign phy_rx[1][0]  = ui_in[4];
assign phy_rx[1][1]  = ui_in[5];
assign phy_rx_v[1]   = ui_in[6];
assign phy_rx_err[1] = ui_in[7];  
// RX2
assign phy_rx[2][0]  = uio_in[0];
assign phy_rx[2][1]  = uio_in[1];
assign phy_rx_v[2]   = uio_in[2];
assign phy_rx_err[2] = uio_in[3];  

// lookup to tx
wire             rmii_tx_v[PORT_CNT-1:0];
wire [PHY_W-1:0] rmii_tx[PORT_CNT-1:0];

wire             phy_tx_v[PORT_CNT-1:0];
wire [PHY_W-1:0] phy_tx[PORT_CNT-1:0];
// TX0 
assign uo_out[0] = phy_tx[0][0];
assign uo_out[1] = phy_tx[0][1];
assign uo_out[2] = phy_tx_v[0];
// TX1 
assign uo_out[5] = phy_tx[1][0];
assign uo_out[6] = phy_tx[1][1];
assign uo_out[7] = phy_tx_v[1];
// TX2
assign uio_out[5] = phy_tx[2][0];
assign uio_out[6] = phy_tx[2][1];
assign uio_out[7] = phy_tx_v[2];

// switch <-> mac tx
wire             mac_tx_v[PORT_CNT-1:0];
wire [PHY_W-1:0] mac_tx[PORT_CNT-1:0];
wire             mac_tx_last[PORT_CNT-1:0];
wire             mac_tx_acc[PORT_CNT-1:0];

genvar i; 
generate 
	for(i = 0; i < PORT_CNT; i=i+1) begin: g_channel
		rmii m_rmii(
			.clk(clk),
			.rst_n(rst_n_q),
			.clk_phase_sel_i(tx_phase),
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
			.data_start_o(mac_rx_start[i]),
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
	.mac_rx_start_i({mac_rx_start[2], mac_rx_start[1], mac_rx_start[0]}),
	
	.mac_tx_v_o({mac_tx_v[2], mac_tx_v[1], mac_tx_v[0]}),
	.mac_tx_o({mac_tx[2], mac_tx[1], mac_tx[0]}),
	.mac_tx_last_o({mac_tx_last[2], mac_tx_last[1], mac_tx_last[0]}),
	
	.mac_tx_acc_i({mac_tx_acc[2], mac_tx_acc[1], mac_tx_acc[0]})
);
endmodule
