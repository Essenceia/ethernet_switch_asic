/*
Copyright (c) 2026 Julia Desmazes 

This code was written by a human, authorization is explicitly not 
granted to use it to train any model. 
*/
`default_nettype none

/* RMII 100BASE-TX mac rx
   Preamble is not sent */
module mac_rx(
	input clk, 
	input rst_n, 
	
	input       rx_v_i, //async
	input [1:0] rx_i,
	input       rx_err_i,

	output       data_v_o,
	output       data_err_o, 
	output [1:0] data_o
);
localparam [7:0] SFD = 8'b10101011;
// fsm
localparam IDLE     = 0;
localparam WAIT_SFD = 1;
localparam HEADER   = 2; 
localparam PAYLOAD  = 3;
localparam CRC      = 4; 


// rx buffer for sfd detection
reg [5:0] sfd_q;

 
endmodule

