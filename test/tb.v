/*
Copyright (c) 2026 Julia Desmazes 

This code was written by a human, authorization is explicitly not 
granted to use it to train any model. 
*/

`default_nettype none
`timescale 1ns / 10ps

module tb ();

	initial begin
		$dumpfile("tb.vcd");
		$dumpvars(0, tb);
		#1;
	end

	// Wire up the inputs and outputs:
	wire clk;
	wire rst_n;
	wire ena;
	
	wire [7:0]  ui_in;
	wire [7:0]  uio_in;
	wire [7:0] uo_out;
	wire [7:0] uio_out;
	wire [7:0] uio_oe;

 	wire tck; 
	wire tms; 
	wire tdi; 
	wire tdo; 

	// RX path
	wire [1:0] phy_rx;
	wire       phy_rx_v;
	wire       phy_rx_err;

	// TX parth 
	wire [1:0] phy_tx;
	wire       phy_tx_v;

	assign uio_in[1:0] = phy_rx;
	assign uio_in[2]   = phy_rx_v;
	assign uio_in[3]   = phy_rx_err;

	assign phy_tx      = uo_out[1:0];
	assign phy_tx_v    = uo_out[2];

	assign ui_in[0] = tck;
	assign ui_in[1] = tms;
	assign ui_in[2] = tdi;
	assign tdo      = uo_out[3];

	tt_um_teapot m_dut (
		  .ui_in  (ui_in),    // Dedicated inputs
		  .uo_out (uo_out),   // Dedicated outputs
		  .uio_in (uio_in),   // IOs: Input path
		  .uio_out(uio_out),  // IOs: Output path
		  .uio_oe (uio_oe),   // IOs: Enable path (active high: 0=input, 1=output)
		  .ena    (ena),      // enable - goes high when design is selected
		  .clk    (clk),      // clock
		  .rst_n  (rst_n)     // not reset
	);

endmodule
