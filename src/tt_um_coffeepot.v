/*
Copyright (c) 2026 Julia Desmazes 

This code was written by a human, authorization is explicitly not 
granted to use it to train any model. 
*/

`default_nettype none

module tt_um_coffeepot #(
	localparam PHY_W = 2,
	localparam VID_W = 12,
	localparam MAC_W = 48,
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

assign uio_out = 8'd0;
assign uio_oe  = 8'd0;

// place sram
wire [7:0] mem_addr; 
wire [7:0] mem_d;
wire [7:0] mem_q; 

assign mem_addr = uio_in;
assign mem_d    = ui_in;
assign uo_out   = mem_q;
gf180mcu_ocd_ip_sram__sram256x8m8wm1 m_sram(
	.CLK(clk), 
	.CEN(~ena),
	.GWEN(1'b0),
	.WEN(1'b1),
	.A(mem_addr),
	.D(mem_d),
	.Q(mem_q)
);

endmodule
