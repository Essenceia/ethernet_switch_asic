/*
Copyright (c) 2026 Julia Desmazes 

This code was written by a human, authorization is explicitly not 
granted to use it to train any model. 
*/

`default_nettype none

module tt_um_coffeepot #(
	localparam PORT_CNT = 3,
	localparam PHY_W = 2,
	localparam MAC_W = 48
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
// IO
assign uio_oe = 8'b11100000;
assign uo_out[4:3] = 2'd0;
assign uio_out[4:0] = 5'd0;

// rst flop
reg rst_n_q; 
always @(posedge clk) 
	rst_n_q <= rst_n; 

// rx to mac rx
wire             phy_rx_v[PORT_CNT-1:0];
wire             phy_rx_err[PORT_CNT-1:0];
wire [PHY_W-1:0] phy_rx[PORT_CNT-1:0];

wire             mac_rx_v[PORT_CNT-1:0];
wire             mac_rx_err[PORT_CNT-1:0];
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

genvar i; 
generate 
	for(i = 0; i < PORT_CNT; i=i+1) begin: g_mac_rx
		mac_rx m_mac_rx(
			.clk(clk),
			.rst_n(rst_n_q),
			.rx_v_i(phy_rx_v[i]),
			.rx_i(phy_rx[i]),
			.rx_err_i(phy_rx_err[i]),
			.data_v_o(mac_rx_v[i]),
			.data_err_o(mac_rx_err[i]),
			.data_o(mac_rx[i])
		);
	end
endgenerate

endmodule
