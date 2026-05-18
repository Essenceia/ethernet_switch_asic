`default_nettype none

/* This RMII assumes full duplex operations, no carrier sense/receiver data valid
   signal will be passed. */
module rmii(
	input 50mhz_clk, 
	input rst_n, 

	output wire [1:0] tx_o;	
	output wire       tx_en_o; // transmit strobe
	
	input wire [1:0] rx_i;  
	input wire       rx_err_i; // error, drop packet

	
	 
);

endmodule
