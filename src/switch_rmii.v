/*
Copyright (c) 2026 Julia Desmazes 

This code was written by a human, authorization is explicitly not 
granted to use it to train any model. 
*/

`default_nettype none

/* This RMII assumes full duplex operations, no carrier sense/receiver data valid
   signal will be passed. */
module switch_rmii #(
	parameter HAS_TX_PHASE = 1
)
(
	input wire clk,
	input wire rst_n, 

	input wire        clk_phase_sel_i,

	output wire       phy_tx_v_o, // transmit strobe
	output wire [1:0] phy_tx_o,	

	input wire        phy_rx_v_i, //async valid, carrier is none idle signal, packet will start on SRD	
	input wire [1:0]  phy_rx_i,
	input wire        phy_rx_err_i, // error, drop packet

	output wire       mac_rx_v_o,
	output wire [1:0] mac_rx_o,
	output wire       mac_rx_err_o,

	input wire        mac_tx_v_i,
	input wire [1:0]  mac_tx_i
);
// TX - adjust clk phase
reg       mac_tx_v_q;
reg [1:0] mac_tx_q;

always @(posedge clk) begin
	mac_tx_v_q <= mac_tx_v_i; 
	mac_tx_q   <= mac_tx_i;
end

generate 
if (HAS_TX_PHASE == 1) begin: g_tx_phase
tx_tt_buffer m_tx_delay(
	.ref_clk(clk),
	.rst_n(rst_n), 

	.clk_phase_sel_i(clk_phase_sel_i),

	.tx_v_i(mac_tx_v_q),
	.tx_i(mac_tx_q),

	.tx_v_o(phy_tx_v_o),
	.tx_o(phy_tx_o)
); 
end else begin : g_no_tx_phase
reg       phy_tx_v_q;
reg [1:0] phy_tx_q;

always @(posedge clk) begin
	phy_tx_v_q <= mac_tx_v_q;
	phy_tx_q   <= mac_tx_q;
end

assign phy_tx_v_o = phy_tx_v_q;
assign phy_tx_o   = phy_tx_q;

end
endgenerate // tx phase

// RX - pass though, flop for timing
reg       mac_rx_v_q;
reg       mac_rx_err_q;
reg [1:0] mac_rx_q;

always @(posedge clk) begin
	if (~rst_n) begin
		mac_rx_v_q   <= 1'b0;
		mac_rx_err_q <= 1'b0;
		mac_rx_q     <= 2'b00;
	end else begin
		mac_rx_v_q   <= phy_rx_v_i;
		mac_rx_err_q <= phy_rx_err_i;
		mac_rx_q     <= phy_rx_i;
	end
end

assign mac_rx_v_o   = mac_rx_v_q; // will fix async valid in mac
assign mac_rx_o     = mac_rx_q; 
assign mac_rx_err_o = mac_rx_err_q;

endmodule
