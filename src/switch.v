/*
Copyright (c) 2026 Julia Desmazes 

This code was written by a human, authorization is explicitly not 
granted to use it to train any model. 
*/

`default_nettype none

module switch #(
	localparam PORT_CNT = 3,
	localparam PHY_W = 2
)(
	input wire clk, 
	input wire rst_n, 

	input wire [PORT_CNT-1:0]       mac_rx_v_i,
	input wire [PORT_CNT*PHY_W-1:0] mac_rx_i,
	input wire [PORT_CNT-1:0]       mac_rx_start_i,

	output wire [PORT_CNT-1:0]       mac_tx_v_o,
	output wire [PORT_CNT*PHY_W-1:0] mac_tx_o,
	output wire [PORT_CNT-1:0]       mac_tx_last_o,

	input  wire [PORT_CNT-1:0]       mac_tx_acc_i
);
localparam PREAMBLE_BYTES = 8; // preamble + sfd
localparam MAC_ADDR_BYTES = 6; 
localparam DATA_DELAY = 8 * (PREAMBLE_BYTES + MAC_ADDR_BYTES) + 2*PHY_W;
localparam BUF_W = DATA_DELAY;
localparam BUF_V_W = DATA_DELAY / PHY_W; 

// buffer incomming data
reg [BUF_W-1:0]   buff_q[PORT_CNT-1:0];
reg [BUF_V_W-1:0] buff_v_q[PORT_CNT-1:0];

genvar i; 
generate 
	for(i = 0; i < PORT_CNT; i=i+1) begin: g_port_buff
		always @(posedge clk) begin
			buff_q[i]   <= {buff_q[i][BUF_W-PHY_W-1:0], mac_rx_i[(i+1)*PHY_W-1-:PHY_W]};
			buff_v_q[i] <= {buff_v_q[i][BUF_V_W-2:0], mac_rx_v_i[i]};
		end
		wire [BUF_W-1:0] debug_buff;
		wire [BUF_V_W-1:0] debug_buff_v;
		assign debug_buff = buff_q[i];
		assign debug_buff_v = buff_v_q[i];
	end
endgenerate

// accumulated mac
localparam MAC_W = MAC_ADDR_BYTES * 8;
localparam MAC_V_CYCLES = MAC_W / PHY_W;
wire [MAC_W-1:0] dst_mac[PORT_CNT-1:0];
wire             dst_mac_v_next[PORT_CNT-1:0];

generate
	for(i = 0; i < PORT_CNT; i=i+1) begin: g_port_mac
		assign dst_mac[i] = buff_q[i][MAC_W-1:0];
		assign dst_mac_v_next[i] = ~buff_v_q[i][MAC_V_CYCLES] & buff_v_q[i][MAC_V_CYCLES-1];
		
		wire [MAC_W-1:0] debug_dst_mac;
		wire             debug_dst_mac_v_next;
		assign debug_dst_mac = dst_mac[i];
		assign debug_dst_mac_v_next = dst_mac_v_next[i];
	end
endgenerate

// arbitor
wire                lookup_req_v;
wire [PORT_CNT-1:0] lookup_req_port; 
wire [MAC_W-1:0]    lookup_mac; 
arbitor m_arbitor(
	.clk(clk),
	.req_early_i({dst_mac_v_next[2], dst_mac_v_next[1],dst_mac_v_next[0]}),
	.req_mac_i({dst_mac[2], dst_mac[1], dst_mac[0]}),
	.req_v_o(lookup_req_v), 
	.req_port_o(lookup_req_port),
	.req_mac_o(lookup_mac)
);

// lookup and dispatch 
wire [PORT_CNT-1:0]              new_disp; 
wire [PORT_CNT*(PORT_CNT-1)-1:0] disp_dir; 
lookup m_lookup(
	.req_v_i(lookup_req_v),
	.req_port_i(lookup_req_port),
	.req_mac_i(lookup_mac), 
	.phy_tx_free_i(mac_tx_acc_i),
	.new_dispatch_o(new_disp),
	.dir_o(disp_dir)
);

// output to mac tx
wire [PORT_CNT-1:0]       mac_tx_v_next;
reg  [PORT_CNT-1:0]       mac_tx_v_q;
wire [PORT_CNT*PHY_W-1:0] mac_tx_next;
reg  [PORT_CNT*PHY_W-1:0] mac_tx_q;

// needs to be hand coded
aiguilleur m_aiguille_tx0(
	.clk(clk), 
	.rst_n(rst_n), 
	.new_dispatch_i(new_disp[0]),
	.dir_i(disp_dir[PORT_CNT-2:0]),
	.mac_rx_v_i({buff_v_q[2][BUF_V_W-1], buff_v_q[1][BUF_V_W-1]}),
	.mac_rx_i  ({buff_q[2][BUF_W-1-:PHY_W], buff_q[1][BUF_W-1-:PHY_W]}),
	.mac_tx_v_o(mac_tx_v_next[0]),
	.mac_tx_o(mac_tx_next[PHY_W-1:0])
);
aiguilleur m_aiguille_tx1(
	.clk(clk), 
	.rst_n(rst_n), 
	.new_dispatch_i(new_disp[1]),
	.dir_i(disp_dir[2*(PORT_CNT-1)-1-:PORT_CNT-1]),
	.mac_rx_v_i({buff_v_q[2][BUF_V_W-1], buff_v_q[0][BUF_V_W-1]}),
	.mac_rx_i  ({buff_q[2][BUF_W-1-:PHY_W], buff_q[0][BUF_W-1-:PHY_W]}),
	.mac_tx_v_o(mac_tx_v_next[1]),
	.mac_tx_o(mac_tx_next[2*PHY_W-1-:PHY_W])
);
aiguilleur m_aiguille_tx2(
	.clk(clk), 
	.rst_n(rst_n), 
	.new_dispatch_i(new_disp[2]),
	.dir_i(disp_dir[3*(PORT_CNT-1)-1-:PORT_CNT-1]),
	.mac_rx_v_i({buff_v_q[1][BUF_V_W-1], buff_v_q[0][BUF_V_W-1]}),
	.mac_rx_i  ({buff_q[1][BUF_W-1-:PHY_W], buff_q[0][BUF_W-1-:PHY_W]}),
	.mac_tx_v_o(mac_tx_v_next[2]),
	.mac_tx_o(mac_tx_next[3*PHY_W-1-:PHY_W])
);

always @(posedge clk) begin
	mac_tx_v_q <= mac_tx_v_next;
	mac_tx_q   <= mac_tx_next;
end

assign mac_tx_v_o    = mac_tx_v_q; 
assign mac_tx_o      = mac_tx_q; 
assign mac_tx_last_o = mac_tx_v_q & ~mac_tx_v_next; 

endmodule
