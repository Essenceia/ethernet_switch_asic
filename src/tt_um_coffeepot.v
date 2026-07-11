/*
Copyright (c) 2026 Julia Desmazes 

This code was written by a human, authorization is explicitly not 
granted to use it to train any model. 
*/

`default_nettype none

module tt_um_coffeepot #(
	localparam PORT_CNT = 3,
	localparam PHY_W = 2
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
wire [7:5] uio_in_unused;
wire       ena_unused; 
// IO
assign uio_oe       = 8'b11100000;
assign uo_out[4:3]  = 2'd0;
assign uio_out[4:0] = 5'd0;

assign uio_in_unused = uio_in[7:5];
assign ena_unused    = ena; 

// tx phase
wire tx_phase;
assign tx_phase = uio_in[4];

// rx to top
wire                      phy_rx_v[PORT_CNT-1:0];
wire                      phy_rx_err[PORT_CNT-1:0];
wire [PORT_CNT*PHY_W-1:0] phy_rx;

// RX0
assign phy_rx[0*PHY_W+0]  = ui_in[0];
assign phy_rx[0*PHY_W+1]  = ui_in[1];
assign phy_rx_v[0]        = ui_in[2];
assign phy_rx_err[0]      = ui_in[3];  
// RX1
assign phy_rx[1*PHY_W+0]  = ui_in[4];
assign phy_rx[1*PHY_W+1]  = ui_in[5];
assign phy_rx_v[1]        = ui_in[6];
assign phy_rx_err[1]      = ui_in[7];  
// RX2
assign phy_rx[2*PHY_W+0]  = uio_in[0];
assign phy_rx[2*PHY_W+1]  = uio_in[1];
assign phy_rx_v[2]        = uio_in[2];
assign phy_rx_err[2]      = uio_in[3];  

// top to tx
wire                      phy_tx_v[PORT_CNT-1:0];
wire [PORT_CNT*PHY_W-1:0] phy_tx;
// TX0 
assign uo_out[0] = phy_tx[0*PHY_W+0];
assign uo_out[1] = phy_tx[0*PHY_W+1];
assign uo_out[2] = phy_tx_v[0];
// TX1 
assign uo_out[5] = phy_tx[1*PHY_W+0];
assign uo_out[6] = phy_tx[1*PHY_W+1];
assign uo_out[7] = phy_tx_v[1];
// TX2
assign uio_out[5] = phy_tx[2*PHY_W+0];
assign uio_out[6] = phy_tx[2*PHY_W+1];
assign uio_out[7] = phy_tx_v[2];

coffeeport #(.PORT_CNT(PORT_CNT), .PHY_W(PHY_W), .HAS_TX_PHASE(1'b1)) m_coffeepot(
.clk(clk), 
.rst_n(rst_n),

.tx_phase_i(tx_phase),

.phy_rx_v_i(phy_rx_v),
.phy_rx_err_i(phy_rx_err),
.phy_rx_data_i(phy_rx),

.phy_tx_v_o(phy_tx_v),
.phy_tx_data_o(phy_tx)
); 

endmodule
