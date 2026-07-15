/*
Copyright (c) 2026 Julia Desmazes 

This code was written by a human, authorization is explicitly not 
granted to use it to train any model. 
*/

`default_nettype none

module aiguilleur #(
	parameter  PHY_W    = 2,
	parameter  PORT_CNT = 3,
	localparam SEL_W    = PORT_CNT-1 
)(
	input wire clk, 
	input wire rst_n, 

	input wire                   new_dispatch_i, 
	input wire [SEL_W-1:0]       dir_i,

	input wire [SEL_W-1:0]       mac_rx_v_i,
	input wire [SEL_W*PHY_W-1:0] mac_rx_i,

	output wire             mac_tx_v_o,
	output wire [PHY_W-1:0] mac_tx_o
);
reg [SEL_W-1:0] sel_onehot_q;
reg             mac_tx_v; 
reg [PHY_W-1:0] mac_tx; 

localparam IDLE     = 2'd0;
localparam PREAMBLE = 2'd1;
localparam PACKET   = 2'd2;

reg [1:0] fsm_q;

always @(posedge clk) begin
	if (~rst_n) begin
		fsm_q        <= IDLE; 
		sel_onehot_q <= {PORT_CNT-1{1'b0}};
	end else begin
		case(fsm_q)
			IDLE: begin
				fsm_q        <= new_dispatch_i ? PREAMBLE: IDLE; 
				sel_onehot_q <= new_dispatch_i? dir_i: {SEL_W{1'b0}}; 
				end
			PREAMBLE: fsm_q <= mac_tx_v ? PACKET: PREAMBLE;
			PACKET: fsm_q <= ~mac_tx_v ? IDLE: PACKET;
			default: begin
				fsm_q <= IDLE; 
				sel_onehot_q <= {SEL_W{1'b0}};
				end
		endcase
	end
end

// valid should be masked in case valid data is being transmitted on an 
// unselected port (eg: start during IPG)
int x; 
always @(*) begin
	mac_tx_v = 1'b0;
	mac_tx = {PHY_W{1'b0}};

	for(x = 0; x < SEL_W; x = x+1) begin
		if (sel_onehot_q[x]) begin 
			mac_tx_v = mac_tx_v | mac_rx_v_i[x];
			mac_tx = mac_tx | mac_rx_i[(x+1)*PHY_W-1-:PHY_W];
		end
	end	
end

assign mac_tx_v_o = |sel_onehot_q & ~((fsm_q == PACKET) & ~mac_tx_v);
assign mac_tx_o   = mac_tx;

endmodule
