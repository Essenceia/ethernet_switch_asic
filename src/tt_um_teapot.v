/*
Copyright (c) 2026 Julia Desmazes 

This code was written by a human, authorization is explicitly not 
granted to use it to train any model. 
*/

`default_nettype none

module tt_um_teapot #(
	localparam PHY_W = 2,
	localparam VID_W = 12,
	localparam MAC_W = 48,
 	parameter [15:0]      APP_ETHTYPE  = 16'h88B5,
	parameter [15:0]      CONF_ETHTYPE = 16'h88B6, 
	parameter [VID_W-1:0] DEFAULT_VID = 12'hDAD,
	parameter [MAC_W-1:0] DEFAULT_MAC = 48'h0090CF00BEEF // nortel manifacturer
)(
	input  wire [7:0] ui_in,    
    output wire [7:0] uo_out,   
    input  wire [7:0] uio_in,   
    output wire [7:0] uio_out,  
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

wire [VID_W-1:0] vid; 
wire [MAC_W-1:0] mac_addr;
wire        clk_phase_sel;

wire        data_rx_v;
wire        data_rx_conf;
wire        data_rx_start;
wire        data_rx_err;
wire [PHY_W-1:0]  data_rx;
wire [MAC_W-1:0] data_rx_src_mac; 

wire        rmii_tx_v; 
wire [PHY_W-1:0] rmii_tx;

wire        mac_tx_v;
wire        mac_tx_last;
wire        mac_tx_acc;
wire [PHY_W-1:0]  mac_tx;
wire [MAC_W-1:0] mac_tx_dst_mac;

wire       mac_rx_err;
wire       mac_rx_v;
wire [PHY_W-1:0] mac_rx;


wire       phy_rx_v_io_in, phy_rx_v_io_out;
wire [PHY_W-1:0] phy_rx_io_in, phy_rx_io_out;
wire       phy_rx_v_io_dir;
wire [1:0] phy_rx_io_dir;
wire       phy_rx_err_in;
wire       phy_rst_n;

// IO
wire [3:0] uio_in_unused;
assign uio_oe[2:0]  = {phy_rx_v_io_dir, phy_rx_io_dir};
assign uio_out[2:0] = {phy_rx_v_io_out, phy_rx_io_out};
assign {phy_rx_v_io_in, phy_rx_io_in[1:0]} = uio_in[2:0];

assign uio_oe[3]   = 1'b0;
assign phy_rx_err_in   = uio_in[3];

assign uio_oe[6:4]  = 3'd0;
assign uio_out[6:3] = 4'd0;
assign uio_in_unused = uio_in[7:4];

assign uio_oe[7]   = 1'b1;
assign uio_out[7]  = phy_rst_n;

// IN
wire tck, tms, tdi; 
wire [6:3] ui_unused;
wire default_tx_phase; 

assign tck = ui_in[0];
assign tms = ui_in[1];
assign tdi = ui_in[2];
assign ui_unused = ui_in[6:3];
assign default_tx_phase = ui_in[7]; 

// OUT 
wire [1:0] phy_tx;
wire       phy_tx_v;
wire       tdo; 

assign uo_out[1:0] = phy_tx;
assign uo_out[2]   = phy_tx_v;
assign uo_out[3]   = tdo;
assign uo_out[7:4] = 4'd0;

// misc
wire ena_unused; 
assign ena_unused = ena; 

// rmii 
rmii m_rmii(
	.clk(clk),
	.rst_n(rst_n),

	.clk_phase_sel_i(clk_phase_sel),

	.phy_rst_n_o(phy_rst_n),

	.phy_rx_v_dir_o(phy_rx_v_io_dir),
	.phy_rx_dir_o(phy_rx_io_dir),
	.phy_rx_v_o(phy_rx_v_io_out),
	.phy_rx_o(phy_rx_io_out),

	.phy_tx_v_o(phy_tx_v),
	.phy_tx_o(phy_tx),

	.phy_rx_v_i(phy_rx_v_io_in),
	.phy_rx_i(phy_rx_io_in),
	.phy_rx_err_i(phy_rx_err_in),

	.mac_rx_v_o(mac_rx_v),
	.mac_rx_o(mac_rx),
	.mac_rx_err_o(mac_rx_err),

	.mac_tx_v_i(rmii_tx_v),
	.mac_tx_i(rmii_tx)
);

// rx mac 
mac_rx #(
	.APP_ETHTYPE(APP_ETHTYPE),
	.CONF_ETHTYPE(CONF_ETHTYPE)
)m_mac_rx(
	.clk(clk),
	.rst_n(rst_n),

	.phy_mac_i(mac_addr),
	.vid_i(vid),

	.rx_v_i(mac_rx_v),
	.rx_i(mac_rx),
	.rx_err_i(mac_rx_err),

	.data_v_o(data_rx_v),
	.data_conf_o(data_rx_conf),
	.data_start_o(data_rx_start),
	.data_err_o(data_rx_err),
	.data_o(data_rx),
	.data_src_mac_o(data_rx_src_mac)
);

//application
app_wrapper #(.PHY_W(PHY_W)) m_app_wrapper(
	.clk(clk),
	.rst_n(rst_n),

	.data_v_i      (data_rx_v),
	.data_conf_i   (data_rx_conf),
	.data_start_i  (data_rx_start),
	.data_err_i    (data_rx_err),
	.data_i        (data_rx),
	.data_src_mac_i(data_rx_src_mac),

	.mac_tx_v_o      (mac_tx_v),
	.mac_tx_last_o   (mac_tx_last),
	.mac_tx_acc_i    (mac_tx_acc),
	.mac_tx_o        (mac_tx),
	.mac_tx_dst_mac_o(mac_tx_dst_mac)
);

// playpen config
mac_conf #(
	.PHY_W(PHY_W),
	.DEFAULT_VID(DEFAULT_VID),
	.DEFAULT_MAC(DEFAULT_MAC)
)m_mac_conf(
	.clk(clk),
	.rst_n(rst_n),

	.default_tx_phase_i(ui_in[7]),
	
	.data_v_i    (data_rx_v),
	.data_conf_i (data_rx_conf),
	.data_start_i(data_rx_start),
	.data_err_i  (data_rx_err),
	.data_i      (data_rx),

	.vid_o          (vid),
	.mac_addr_o     (mac_addr),
	.clk_phase_sel_o(clk_phase_sel)
);

// tx mac
mac_tx #(
	.PHY_W(PHY_W),
	.APP_ETHTYPE(APP_ETHTYPE)
) m_mac_tx(
	.clk(clk),
	.rst_n(rst_n),
	
	.phy_mac_i(mac_addr),// conf
	
	.data_v_i(mac_tx_v),
	.data_last_i(mac_tx_last),
	.data_i(mac_tx),
	.data_dst_mac_i(mac_tx_dst_mac),
	.data_acc_o(mac_tx_acc),

	.phy_v_o(rmii_tx_v),
	.phy_o(rmii_tx)
);

endmodule
