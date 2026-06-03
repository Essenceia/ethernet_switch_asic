/*
Copyright (c) 2026 Julia Desmazes 

This code was written by a human, authorization is explicitly not 
granted to use it in training data. 
*/

`default_nettype none

/* 
Tiny Tapeout specific output data dephasing to comphesate for the 
propagation delay between the clk source, the ASIC internal FF and the 
external MAC's TX IO.
This module is going to need an accompanying sdc tcl script and double
checking the implementation results. 

credit for pointing the timing issue out: tnt
*/ 
module tx_tt_buffer(
	input wire ref_clk, 
	input wire rst_n,
	
	input wire clk_phase_sel_i, // use dephased clk by 180 to drive tx output

	input wire tx_v_i, 
	input wire [1:0] tx_i, 

	output wire tx_v_o, 
	output wire [1:0] tx_o
); 
wire      inner_clk; 
reg       tx_v_q; 
reg [1:0] tx_q;
reg       clk_phase_sel_q;

(* DONT_TOUCH = "yes" *)
wire       tx_v_buff;
(* DONT_TOUCH = "yes" *)
wire [1:0] tx_buff;

always @(posedge ref_clk) 
	if (~rst_n)	clk_phase_sel_q <= clk_phase_sel_i;

assign inner_clk = clk_phase_sel_q ? ~ref_clk : ref_clk; 

// shooting design opt a bit until it stops being too good at creating
// hold violations
assign tx_v_buff = ~(~tx_v_i);
assign tx_buff   = ~(~tx_i); 

always @(posedge inner_clk) begin
	tx_v_q <= tx_v_buff; 
	tx_q   <= tx_buff; 
end

assign tx_v_o = tx_v_q; 
assign tx_o   = tx_q;
endmodule
