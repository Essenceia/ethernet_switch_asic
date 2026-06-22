# Basys3 rev D xdc

# Switches
set_property -dict { PACKAGE_PIN V17   IOSTANDARD LVCMOS33 PULLDOWN true } [get_ports {switch_i[0]}]
set_property -dict { PACKAGE_PIN V16   IOSTANDARD LVCMOS33 PULLDOWN true } [get_ports {switch_i[1]}]
set_property -dict { PACKAGE_PIN W16   IOSTANDARD LVCMOS33 PULLDOWN true } [get_ports {switch_i[2]}]

# LEDs
set_property -dict { PACKAGE_PIN U16   IOSTANDARD LVCMOS33 PULLDOWN true } [get_ports {led_o[0]}]
set_property -dict { PACKAGE_PIN E19   IOSTANDARD LVCMOS33 PULLDOWN true } [get_ports {led_o[1]}]
set_property -dict { PACKAGE_PIN U19   IOSTANDARD LVCMOS33 PULLDOWN true } [get_ports {led_o[2]}]
set_property -dict { PACKAGE_PIN V19   IOSTANDARD LVCMOS33 PULLDOWN true } [get_ports {led_o[3]}]
set_property -dict { PACKAGE_PIN W18   IOSTANDARD LVCMOS33 PULLDOWN true } [get_ports {led_o[4]}]
set_property -dict { PACKAGE_PIN U15   IOSTANDARD LVCMOS33 PULLDOWN true } [get_ports {led_o[5]}]
set_property -dict { PACKAGE_PIN U14   IOSTANDARD LVCMOS33 PULLDOWN true } [get_ports {led_o[6]}]
set_property -dict { PACKAGE_PIN V14   IOSTANDARD LVCMOS33 PULLDOWN true } [get_ports {led_o[7]}]
set_property -dict { PACKAGE_PIN V13   IOSTANDARD LVCMOS33 PULLDOWN true } [get_ports {led_o[8]}]
set_property -dict { PACKAGE_PIN V3    IOSTANDARD LVCMOS33 PULLDOWN true } [get_ports {led_o[9]}]
set_property -dict { PACKAGE_PIN W3    IOSTANDARD LVCMOS33 PULLDOWN true } [get_ports {led_o[10]}]
set_property -dict { PACKAGE_PIN U3    IOSTANDARD LVCMOS33 PULLDOWN true } [get_ports {led_o[11]}]
set_property -dict { PACKAGE_PIN P3    IOSTANDARD LVCMOS33 PULLDOWN true } [get_ports {led_o[12]}]
set_property -dict { PACKAGE_PIN N3    IOSTANDARD LVCMOS33 PULLDOWN true } [get_ports {led_o[13]}]
set_property -dict { PACKAGE_PIN P1    IOSTANDARD LVCMOS33 PULLDOWN true } [get_ports {led_o[14]}]
set_property -dict { PACKAGE_PIN L1    IOSTANDARD LVCMOS33 PULLDOWN true } [get_ports {led_o[15]}]

#Pmod Header JA
set_property -dict { PACKAGE_PIN J1   IOSTANDARD LVCMOS33 } [get_ports {phy1_rx_i[0]}];
set_property -dict { PACKAGE_PIN L2   IOSTANDARD LVCMOS33 } [get_ports {phy1_rx_i[1]}];
set_property -dict { PACKAGE_PIN J2   IOSTANDARD LVCMOS33 } [get_ports {phy1_rx_v_i}];
set_property -dict { PACKAGE_PIN G2   IOSTANDARD LVCMOS33 } [get_ports {phy1_rx_err_i}];
set_property -dict { PACKAGE_PIN H1   IOSTANDARD LVCMOS33 LVCMOS33 DRIVE 16 SLEW FAST PULLDOWN true } [get_ports {phy1_tx_o[0]}];
set_property -dict { PACKAGE_PIN K2   IOSTANDARD LVCMOS33 LVCMOS33 DRIVE 16 SLEW FAST PULLDOWN true } [get_ports {phy1_tx_o[1]}];
set_property -dict { PACKAGE_PIN H2   IOSTANDARD LVCMOS33 LVCMOS33 DRIVE 16 SLEW FAST PULLDOWN true } [get_ports {phy1_tx_v_o}];
set_property -dict { PACKAGE_PIN G3   IOSTANDARD LVCMOS33 PULLDOWN true } [get_ports {clk_phy_o}];

#Pmod Header JB
#set_property -dict { PACKAGE_PIN A14   IOSTANDARD LVCMOS33 } [get_ports {phy_rx_io[0]}];
#set_property -dict { PACKAGE_PIN A16   IOSTANDARD LVCMOS33 } [get_ports {phy_rx_io[1]}];
#set_property -dict { PACKAGE_PIN B15   IOSTANDARD LVCMOS33 } [get_ports {phy_rx_v_io}];
#set_property -dict { PACKAGE_PIN B16   IOSTANDARD LVCMOS33 } [get_ports {phy_rx_err_io}];
#set_property -dict { PACKAGE_PIN A15   IOSTANDARD LVCMOS33 } [get_ports {pin_io[4]}];
#set_property -dict { PACKAGE_PIN A17   IOSTANDARD LVCMOS33 } [get_ports {pin_io[5]}];
#set_property -dict { PACKAGE_PIN C15   IOSTANDARD LVCMOS33 } [get_ports {pin_io[6]}];
#set_property -dict { PACKAGE_PIN C16   IOSTANDARD LVCMOS33 } [get_ports {phy_rst_n_o}];

# Pmod Header JC
set_property -dict { PACKAGE_PIN K17   IOSTANDARD LVCMOS33 } [get_ports {phy0_rx_i[0]}];
set_property -dict { PACKAGE_PIN M18   IOSTANDARD LVCMOS33 } [get_ports {phy0_rx_i[1]}];
set_property -dict { PACKAGE_PIN N17   IOSTANDARD LVCMOS33 } [get_ports {phy0_rx_v_i}];
set_property -dict { PACKAGE_PIN P18   IOSTANDARD LVCMOS33 } [get_ports {phy0_rx_err_i}];
set_property -dict { PACKAGE_PIN L17   IOSTANDARD LVCMOS33 PULLDOWN true } [get_ports {clk_phy0_i}];
set_property -dict { PACKAGE_PIN M19   IOSTANDARD LVCMOS33 DRIVE 16 SLEW FAST PULLDOWN true } [get_ports {phy0_tx_o[0]}];
set_property -dict { PACKAGE_PIN P17   IOSTANDARD LVCMOS33 DRIVE 16 SLEW FAST PULLDOWN true } [get_ports {phy0_tx_o[1]}];
set_property -dict { PACKAGE_PIN R18   IOSTANDARD LVCMOS33 DRIVE 16 SLEW FAST PULLDOWN true } [get_ports {phy0_tx_v_o}];

#Pmod Header JXADC
#set_property -dict { PACKAGE_PIN J3   IOSTANDARD LVCMOS33 } [get_ports {JXADC_o[0]}];#Sch name = XA1_P
#set_property -dict { PACKAGE_PIN L3   IOSTANDARD LVCMOS33 } [get_ports {JXADC_o[1]}];#Sch name = XA2_P
#set_property -dict { PACKAGE_PIN M2   IOSTANDARD LVCMOS33 } [get_ports {JXADC_o[2]}];#Sch name = XA3_P
#set_property -dict { PACKAGE_PIN N2   IOSTANDARD LVCMOS33 } [get_ports {JXADC_o[3]}];#Sch name = XA4_P
#set_property -dict { PACKAGE_PIN K3   IOSTANDARD LVCMOS33 } [get_ports {JXADC_o[4]}];#Sch name = XA1_N
#set_property -dict { PACKAGE_PIN M3   IOSTANDARD LVCMOS33 } [get_ports {JXADC_o[5]}];#Sch name = XA2_N
#set_property -dict { PACKAGE_PIN M1   IOSTANDARD LVCMOS33 } [get_ports {JXADC_o[6]}];#Sch name = XA3_N
#set_property -dict { PACKAGE_PIN N1   IOSTANDARD LVCMOS33 } [get_ports {JXADC_o[7]}];#Sch name = XA4_N

# tie unused pins
set_property -dict { PACKAGE_PIN W7   IOSTANDARD LVCMOS33 } [get_ports {unused_o[0]}]
set_property -dict { PACKAGE_PIN W6   IOSTANDARD LVCMOS33 } [get_ports {unused_o[1]}]
set_property -dict { PACKAGE_PIN U8   IOSTANDARD LVCMOS33 } [get_ports {unused_o[2]}]
set_property -dict { PACKAGE_PIN V8   IOSTANDARD LVCMOS33 } [get_ports {unused_o[3]}]
set_property -dict { PACKAGE_PIN U5   IOSTANDARD LVCMOS33 } [get_ports {unused_o[4]}]
set_property -dict { PACKAGE_PIN V5   IOSTANDARD LVCMOS33 } [get_ports {unused_o[5]}]
set_property -dict { PACKAGE_PIN U7   IOSTANDARD LVCMOS33 } [get_ports {unused_o[6]}]
set_property -dict { PACKAGE_PIN V7   IOSTANDARD LVCMOS33 } [get_ports {unused_o[7]}]
set_property -dict { PACKAGE_PIN U2   IOSTANDARD LVCMOS33 } [get_ports {unused_o[8]}]
set_property -dict { PACKAGE_PIN U4   IOSTANDARD LVCMOS33 } [get_ports {unused_o[9]}]
set_property -dict { PACKAGE_PIN V4   IOSTANDARD LVCMOS33 } [get_ports {unused_o[10]}]
set_property -dict { PACKAGE_PIN W4   IOSTANDARD LVCMOS33 } [get_ports {unused_o[11]}]

## Configuration options, can be used for all designs
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]

## SPI configuration mode options for QSPI boot, can be used for all designs
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]

# phy_clk
set clk_phy0 "clk_phy0_i"
create_clock -add -name $clk_phy0 -period 20.00 -waveform {0 10} [get_ports $clk_phy0]
set phy1_clk "clk_phy1_i"
create_clock -add -name $phy1_clk -period 20.00 -waveform {0 10} [get_ports $phy1_clk]
# pll clock creation infered by tools and pll params

# mux paths 
# TX0 
set dephase_phy0_tx_clk_net [get_nets -hier -regexp ".*g_channel.0.*/inner_clk" ]
set dephase_phy0_tx_clk_0 "dephase_phy0_tx_clk_0"
set dephase_phy0_tx_clk_1 "dephase_phy0_tx_clk_1"
create_generated_clock -name $dephase_phy0_tx_clk_0 -source [get_ports $clk_phy0] -master_clock $clk_phy0 -divide_by 1 $dephase_phy0_tx_clk_net -add
create_generated_clock -name $dephase_phy0_tx_clk_1 -source [get_ports $clk_phy0] -master_clock $clk_phy0 -divide_by 1 -invert $dephase_phy0_tx_clk_net -add 
set_clock_groups -logically_exclusive -group $dephase_phy0_tx_clk_0 -group $dephase_phy0_tx_clk_1
 
#TX1
set dephase_phy1_tx_clk_net [get_nets -hier -regexp ".*g_channel.1.*/inner_clk" ]
set dephase_phy1_tx_clk_0 "dephase_phy1_tx_clk_0"
set dephase_phy1_tx_clk_1 "dephase_phy1_tx_clk_1"
create_generated_clock -name $dephase_phy1_tx_clk_0 -source [get_ports $clk_phy1] -master_clock $clk_phy1 -divide_by 1 $dephase_phy1_tx_clk_net -add
create_generated_clock -name $dephase_phy1_tx_clk_1 -source [get_ports $clk_phy1] -master_clock $clk_phy1 -divide_by 1 -invert $dephase_phy1_tx_clk_net -add 
set_clock_groups -logically_exclusive -group $dephase_phy1_tx_clk_0 -group $dephase_phy1_tx_clk_1

# lan8720a configs
set ::env(PHY_RX0_PINS) [get_ports -regexp phy0_rx.*]
set ::env(PHY_RX1_PINS) [get_ports -regexp phy1_rx.*]
set ::env(PHY_TX0_PINS) [get_ports -regexp phy0_tx.*]
set ::env(PHY_TX1_PINS) [get_ports -regexp phy1_tx.*]


set toval 14
set tohold 3
# RX0
set_input_delay -clock ${clk_phy0} -max ${toval} $::env(PHY_RX0_PINS)
set_input_delay -clock ${clk_phy0} -min ${tohold} $::env(PHY_RX0_PINS) 
# RX1
set_input_delay -clock ${clk_phy1} -max ${toval} $::env(PHY_RX1_PINS)
set_input_delay -clock ${clk_phy1} -min ${tohold} $::env(PHY_RX1_PINS) 

set tsu 4
set tihold -1.5
# TX0
set_output_delay -clock $dephase_phy0_tx_clk0 -max ${tsu} $::env(PHY_TX0_PINS)
set_output_delay -clock $dephase_phy0_tx_clk0 -min ${tihold} $::env(PHY_TX0_PINS)
set_output_delay -clock $dephase_phy0_tx_clk1 -max ${tsu} $::env(PHY_TX0_PINS) -add_delay
set_output_delay -clock $dephase_phy0_tx_clk1 -min ${tihold} $::env(PHY_TX0_PINS) -add_delay
# TX1
set_output_delay -clock $dephase_phy1_tx_clk0 -max ${tsu} $::env(PHY_TX1_PINS)
set_output_delay -clock $dephase_phy1_tx_clk0 -min ${tihold} $::env(PHY_TX1_PINS)
set_output_delay -clock $dephase_phy1_tx_clk1 -max ${tsu} $::env(PHY_TX1_PINS) -add_delay
set_output_delay -clock $dephase_phy1_tx_clk1 -min ${tihold} $::env(PHY_TX1_PINS) -add_delay

