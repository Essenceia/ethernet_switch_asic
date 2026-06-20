/*
Copyright (c) 2026 Julia Desmazes 

This code was written by a human, authorization is explicitly not 
granted to use it to train any model. 
*/

`default_nettype none

/* Guaranties no duplicate entries */
module mac_addr_table #(
	parameter N = 4, // number of entries
	parameter MAC_W = 48,
	parameter PORT_CNT = 3
)(
	input wire clk, 
	input wire rst_n, 

	input wire rd_v_i, 
	input wire [MAC_W-1:0] rd_mac_i, 

	input wire wr_v_i, 
	input wire [MAC_W-1:0] wr_mac_i, 
	input wire [PORT_CNT-1:0] wr_port_i, 
	
	output wire                hit_v_o, 
	output wire [PORT_CNT-1:0] hit_port_o
);
/* memory line layout 
[ MAC 48b ][ PORT 2b ][ TTNN 4b ]

MAC  mac address
PORT compressed port index 
TTNN time to num num (ageing mechanism) 
*/
localparam PORT_IDX_W = $clog2(PORT_CNT);
localparam TTNN_W = 4;

// in the absence of a CAM ( TODO: design an analog CAM ) 
reg [MAC_W-1:0]      mem_mac_q[N-1:0];
reg [PORT_IDX_W-1:0] mem_port_q[N-1:0];
reg [TTNN_W-1:0]     mem_ttnn_q[N-1:0];

// parallel lookup
wire [N-1:0] mac_hit; 
wire [N-1:0] alive_v; 

genvar i; 
generate
	for(i=0; i < N; i=i+1)begin: g_parallel_lookup
		assign mac_hit[i] = mem_mac_q[i] == rd_mac_i; 
		assign alive_v[i] = |mem_ttnn_q[i]; 
	end
endgenerate 

wire [PORT_IDX_W-1:0] port_hit; 
always @(*) begin
	(* parallel_case *)
	casez(mac_hit)
		4'b???1: port_hit = mem_port_q[0];
		4'b??1?: port_hit = mem_port_q[1];
		4'b?1??: port_hit = mem_port_q[2];
		4'b1???: port_hit = mem_port_q[3];
		default: port_hit = {PORT_IDX_W{1'bX}};
	endcase
end

assign hit_v_o = |(mac_hit_i & alive_v);
assign hit_port_o = port_hit; 

endmodule 
