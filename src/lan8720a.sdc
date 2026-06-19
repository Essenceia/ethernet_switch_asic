# LAN8720A RMII interface timing constraints in 100BASE-TX mode using REF_CLK IN MODE
# timing signal names will be following the LAN8720A datasheet naming, and so will be 
# expressed from the perspective of the PHY chip and not the ASIC 

set ref_clk [get_clocks $::env(CLOCK_PORT)] 

# output direction (input to the ASIC) RXD[1:0], RXER, CRS_DV (RXV)
# valid from rising edge of refclk
set toval 14
# hold from rising edge of refclk
set tohold 3

set_input_delay -clock ${ref_clk} -max ${toval} $::env(PHY_RX_PINS)
set_input_delay -clock ${ref_clk} -min ${tohold} $::env(PHY_RX_PINS) 

# input direction (output from the ASIC) TXD[1:0] TXEN (TXV)  
# setup time to rising edge for the refclk
set tsu 4
# input hold time after rising edge of refclk
set tihold -1.5

set_output_delay -clock $::env(OUTPUT_CLOCK_TX0) -max ${tsu} $::env(PHY_TX0_PINS)
set_output_delay -clock $::env(OUTPUT_CLOCK_TX0) -min ${tihold} $::env(PHY_TX0_PINS)

set_output_delay -clock $::env(OUTPUT_CLOCK_TX1) -max ${tsu} $::env(PHY_TX1_PINS)
set_output_delay -clock $::env(OUTPUT_CLOCK_TX1) -min ${tihold} $::env(PHY_TX1_PINS)

set_output_delay -clock $::env(OUTPUT_CLOCK_TX2) -max ${tsu} $::env(PHY_TX2_PINS)
set_output_delay -clock $::env(OUTPUT_CLOCK_TX2) -min ${tihold} $::env(PHY_TX2_PINS)

