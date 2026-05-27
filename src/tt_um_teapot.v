/*
Copyright (c) 2026 Julia Desmazes 

This code was written by a human, authorization is explicitly not 
granted to use it to train any model. 
*/

`default_nettype none

module tt_um_teapot (
    input  wire [7:0] ui_in,    
    output wire [7:0] uo_out,   
    input  wire [7:0] uio_in,   
    output wire [7:0] uio_out,  
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

wire [11:0] vid; 
wire [47:0] mac_addr;
wire        clk_phase_sel;

wire [1:0] mcu_tx_cmd;
wire [1:0] mcu_tx;

wire        data_rx_v;
wire        data_rx_conf;
wire        data_rx_start;
wire        data_rx_err;
wire [1:0]  data_rx;
wire [47:0] data_rx_src_mac; 

wire       mac_tx_v;
wire       mac_tx_start;
wire [1:0] mac_tx;
wire       mac_rx_err;
wire       mac_rx_v;
wire [1:0] mac_rx;


wire       phy_rx_v_io_in, phy_rx_v_io_out;
wire [1:0] phy_rx_io_in, phy_rx_io_out;
wire       phy_rx_v_io_dir;
wire [1:0] phy_rx_io_dir;
wire       phy_rx_err_in;
wire       phy_rst_n;

// IO
assign uio_oe[2:0]  = {phy_rx_v_io_dir, phy_rx_io_dir};
assign uio_out[2:0] = {phy_rx_v_io_out, phy_rx_io_out};
assign {phy_rx_v_io_in, phy_rx_io_in[1:0]} = uio_in[2:0];

assign uio_oe[3]   = 1'b0;
assign phy_rx_err_in   = uio_in[3];

assign uio_oe[7]   = 1'b1;
assign uio_out[7]  = phy_rst_n;

// IO - unsued
assign uio_oe[6:4]  = 3'd0;
assign uio_out[6:3] = 4'd0;
wire [3:0] uio_in_unused;
assign uio_in_unused = uio_in[7:4];

// IN
wire [3:0] in_unused; 
assign in_unused = ui_in[3:0];

assign mcu_tx     = ui_in[5:4];
assign mcu_tx_cmd = ui_in[7:6];

// OUT 
wire [1:0] phy_tx;
wire       phy_tx_v;

assign uo_out[1:0] = phy_tx;
assign uo_out[2]   = phy_tx_v;
assign uo_out[3]   = 1'b0;
assign uo_out[5:4] = mcu_rx;
assign uo_out[7:6] = mcu_rx_cmd;

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

	.mac_tx_v_i(mac_tx_v),
	.mac_tx_i(mac_tx)
);

// rx mac 
mac_rx m_mac_rx(
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
	.data_src_mac(data_src_mac)
);

//application
app_wrapper m_app_wrapper(
	.clk(clk),
	.rst_n(rst_n),

	.data_v_i      (data_rx_v),
	.data_conf_i   (data_rx_conf),
	.data_start_i  (data_rx_start),
	.data_err_i    (data_rx_err),
	.data_i        (data_rx),
	.data_src_mac_i(data_rx_src_mac),

	.mac_tx_v_o      (),
	.mac_tx_acc_o    (),
	.mac_tx_o        (),
	.mac_tx_dst_mac_o()
);

// playpen config
mac_conf m_mac_conf(
	.clk(clk),
	.rst_n(rst_n),

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

endmodule
