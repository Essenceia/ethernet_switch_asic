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
localparam DATA_DELAY = 8 * 8 + PHY_W; // preamble + sfd
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

wire [PORT_CNT-1:0]              new_disp; 
wire [PORT_CNT*(PORT_CNT-1)-1:0] disp_dir; 

dispatcher_broadcast m_dispatcher(
	.new_req_i(mac_rx_start_i), 
	.free_i(mac_tx_acc_i), 
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
