`default_nettype none

/* This RMII assumes full duplex operations, no carrier sense/receiver data valid
   signal will be passed. */
module rmii(
	input 50mhz_clk, 
	input rst_n, 

	output wire       phy_rst_n, // latch config on rst release

	output wire       tx_en_o, // transmit strobe
	output wire [1:0] tx_o,	

	output wire      rx_v_dir_o, // CRS_DV dir
	output wire      rst_mode2_o,

	input wire       rx_v_i, //async valid, carrier is none idle signal, packet will start on SRD	
	input wire [1:0] rx_i,
	input wire       rx_err_i // error, drop packet
);
localparam [3:0] RST_CYCLES = 4'15;
localparam [2:0] RST_MODE = 3'b011; // full-duplex 100BASE-TX 

reg       tx_en_q;
reg [1:0] tx_q;

// fsm 
localparam PHY_RST = 0; 
localparam IDLE = 1; 
localparam PKT = 2
endmodule
