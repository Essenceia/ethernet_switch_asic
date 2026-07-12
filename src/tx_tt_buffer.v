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
	
	input wire clk_phase_sel_i, // use dephased clk by 180 to drive tx output

	input wire tx_v_i, 
	input wire [1:0] tx_i, 

	output wire tx_v_o, 
	output wire [1:0] tx_o
);
wire      ref_clk_inv; 
 
(* keep *)wire inner_clk; 

reg       tx_v_q; 
reg [1:0] tx_q;
reg       clk_phase_sel_q;

always @(posedge ref_clk) 
	clk_phase_sel_q <= clk_phase_sel_i;

`ifdef SCL_gf180mcu_fd_sc_mcu7t5v0
gf180mcu_fd_sc_mcu7t5v0__clkinv_1 m_ref_clk_inv(
	.I(ref_clk),
	.ZN(ref_clk_inv)
);

gf180mcu_fd_sc_mcu7t5v0__mux2_2 m_ref_clk_mux(
	.I0(ref_clk_inv),
	.I1(ref_clk),
	.S(clk_phase_sel_q),
	.Z(inner_clk)
);

`else
assign ref_clk_inv = ~ref_clk;
assign inner_clk = clk_phase_sel_q ? ref_clk_inv: ref_clk; 
`endif

always @(posedge inner_clk) begin
	tx_v_q <= tx_v_i; 
	tx_q   <= tx_i; 
end

assign tx_v_o = tx_v_q; 
assign tx_o   = tx_q;
endmodule
