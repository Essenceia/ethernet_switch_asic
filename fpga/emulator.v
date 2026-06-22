`default_nettype none

module emulator #(
	parameter SWITCH_W = 3,
	parameter PMOD_W = 8,
	parameter LED_W = 16
)
(
	// PmodC	
   	input wire        clk_phy0_i, /* RMII ref clk 50MHz */
	input  wire [1:0] phy0_rx_i,
	input  wire       phy0_rx_v_i,
	input  wire       phy0_rx_err_i,
	output wire [1:0] phy0_tx_o,
	output wire       phy0_tx_v_o,

   	input wire        clk_phy1_i, /* RMII ref clk 50MHz */
	input  wire [1:0] phy1_rx_i,
	input  wire       phy1_rx_v_i,
	input  wire       phy1_rx_err_i,
	output wire [1:0] phy1_tx_o,
	output wire       phy1_tx_v_o,

	// Misc
	input  wire [SWITCH_W-1:0] switch_i,
	output wire [LED_W-1:0]   led_o,

	output wire [11:0]        unused_o
);
wire [1:0] uo_out_unused; 

wire pll_phy0_lock;
wire pll_phy1_lock;
reg  pll_phy0_lock_q;
reg  pll_phy1_lock_q;
wire ena;
wire rst_async;
 
wire [7:0] ui_in;
wire [7:0] uio_in; 

wire [7:0] uo_out; 
wire [7:0] uio_out;
wire [7:0] uio_oe;

wire tx_phase_async;

/* clk */
wire clk_phy0;
pll m_phy0_pll(
	.clk_i(clk_phy0_i),
	.rst_async_i(rst_async), 
	.locked_o(pll_phy0_lock),
	.clk_o(clk_phy0)
);

wire clk_phy1;
pll m_phy1_pll(
	.clk_i(clk_phy1_i),
	.rst_async_i(rst_async),
	.locked_o(pll_phy1_lock),
	.clk_o(clk_phy1)
);

/* phy1 cdc, 
 * domain cross: clk_phy1 -> clk_phy0 */ 
wire [1:0] phy1_rx_cdc;
wire       phy1_rx_v_cdc;
wire       phy1_rx_err_cdc;

metasync_cdc #(.DATA_W(4)) m_cdc_phy1_rx(
	.wclk(clk_phy1),
	.wdata({phy1_rx_err_i, phy1_rx_v_i, phy1_rx_i}),
	.rclk(clk_phy0),
	.rrst_n(rst_async),
	.rdata({phy1_rx_err_cdc, phy1_rx_v_cdc, phy1_rx_cdc})
);

wire [1:0] phy1_tx_cdc;
wire       phy1_tx_v_cdc;
metasync_cdc #(.DATA_W(3)) m_cdc_phy1_tx(
	.wclk(clk_phy0),
	.wdata({phy1_tx_v_cdc, phy1_tx_cdc}),
	.rclk(clk_phy1),
	.rrst_n(rst_async),
	.rdata({phy1_tx_v_o, phy1_tx_o})
);


/* debug leds */
assign led_o[0] = rst_async;
assign led_o[1] = tx_phase_async;
assign led_o[2] = ena;
assign led_o[3] = clk_phy0;
assign led_o[4] = pll_phy0_lock_q; 
assign led_o[5] = pll_phy1_lock_q; 

assign led_o[15:6] = 10'd0;

assign unused_o = {4'h0, 1'b1, {7{1'b1}}}; // an, dp, seg

/* switch, okay with bounce */
assign rst_async      = switch_i[0];
assign tx_phase_async = switch_i[1];

debounce m_switch_debounce(
	.clk(clk_phy0),
	.rst_async(rst_async),
	.switch_i(switch_i[2]),
	.switch_o(ena)
);

always @(posedge clk_phy0 or posedge rst_async) begin
	if (rst_async) begin
		pll_phy0_lock_q <= 1'b0;
		pll_phy1_lock_q <= 1'b0;
	end else begin
		pll_phy0_lock_q <= pll_phy0_lock;
		pll_phy1_lock_q <= pll_phy1_lock;
	end
end

/* design top level */ 
(* MARK_DEBUG = "true" *) wire [1:0] debug_phy0_tx;
(* MARK_DEBUG = "true" *) wire       debug_phy0_tx_v;
(* MARK_DEBUG = "true" *) wire [1:0] debug_phy1_tx;
(* MARK_DEBUG = "true" *) wire       debug_phy1_tx_v;
assign debug_phy0_tx_v = phy0_tx_v_o;
assign debug_phy0_tx   = phy0_tx_o;
assign debug_phy1_tx_v = phy1_tx_v_o;
assign debug_phy1_tx   = phy1_tx_o;

// IN
assign ui_in[1:0] = phy0_rx_i;
assign ui_in[2]   = phy0_rx_v_i;
assign ui_in[3]   = phy0_rx_err_i;
assign ui_in[5:4] = phy1_rx_cdc;
assign ui_in[6]   = phy1_rx_v_cdc;
assign ui_in[7]   = phy1_rx_err_cdc;

// OUT
assign phy0_tx_o      = uo_out[1:0];
assign phy0_tx_v_o    = uo_out[2];
assign uo_out_unused  = uo_out[4:3];
assign phy1_tx_cdc    = uo_out[6:5];
assign phy1_tx_v_cdc  = uo_out[7];

// IO 
// phy2 unconnected for fpga test
assign uio_in[3:0] = {4{1'b0}};
assign uio_in[4]   = tx_phase_async;
assign uio_in[7:5] = {3{1'b0}};

wire [7:0] uio_oe_unused, uio_out_unused;
assign uio_oe_unused  = uio_oe;
assign uio_out_unused = uio_out; 

tt_um_coffeepot m_top(
	.ui_in(ui_in),
	.uo_out(uo_out),
	.uio_in(uio_in),
	.uio_out(uio_out),
	.uio_oe(uio_oe),
	.ena(ena),
	.clk(clk_phy0),
	.rst_n(~rst_async)
);

endmodule
