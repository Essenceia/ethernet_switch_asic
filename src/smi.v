`default_nettype none

/* Serial Management Interface (SMI) as defined by clause 22 of 802.3
   Modules creates a brige to read these registers over JTAG from the
   ASIC.

   Designed to work with the LAN8720A(I) chip.
   MDIO data is captured on the rising edge, it is recomended to change
   data at the middle of the asserted half period.
*/
module smi #(
	parameter MDC_PERIOD = 20 // supposing default clk runs at 50MHz, gives 1000ns between edge, min 400ns
	)(
	input clk, 
	input rst_n, 

	output mdc_o, // aperiodic clk (min edge t = 400ns)
	input  mdio_i,
	output mdio_o,
	output mdio_dir_o, //0=input, 1=output 

);
localparam MDC_PERIOD_HALF = MDC_PERIOD/2;
localparam MDIO_DATA_SWITCH = MDC_PERIOD_HALF/2;


endmodule
