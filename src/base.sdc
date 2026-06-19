# read librelane base sdc before overwritting it
read_sdc $::env(SCRIPTS_DIR)/base.sdc

proc get_first_output_pin { instance } {
  set dir "output" 
  puts "pin iter [$instance pin_iterator]"
  set iter [$instance pin_iterator]
  while {[$iter has_next]} {
    set pin [$iter next]
    set pin_dir [get_property $pin "direction"]
    if { [lsearch $dir $pin_dir] !=  -1 } {
	  puts "found pin dir $pin_dir on pin $pin"
      return $pin
    }
  }
}

proc get_all_dff_clk_port { clk } {
	set ret {}
	set cells [get_cells [all_registers -clock $clk ]]
	foreach cell $cells {
		set dff_name [get_name $cell]
		set clk_pin [get_pin ${dff_name}/CLK]
  		lappend ret $clk_pin
	}
	return $ret
}

set ref_clk_tx0_mux_pin [get_first_output_pin [get_cells -hierarchical -regexp ".*g_channel0.*m_ref_clk_mux"]]
set ref_clk_tx1_mux_pin [get_first_output_pin [get_cells -hierarchical -regexp ".*g_channel1.*m_ref_clk_mux"]]
set ref_clk_tx2_mux_pin [get_first_output_pin [get_cells -hierarchical -regexp ".*g_channel2.*m_ref_clk_mux"]]

set ::env(OUTPUT_CLOCK_TX0) "dephase_clk_0"
set ::env(OUTPUT_CLOCK_TX1) "dephase_clk_1"
set ::env(OUTPUT_CLOCK_TX2) "dephase_clk_2"

# double generated clock from same source not supported by openraod cts 
create_generated_clock -name $::env(OUTPUT_CLOCK_0) -source [get_ports $::env(CLOCK_PORT)] -master_clock [get_clocks $::env(CLOCK_PORT)] -combinational $ref_clk_tx0_mux_pin -add
create_generated_clock -name $::env(OUTPUT_CLOCK_1) -source [get_ports $::env(CLOCK_PORT)] -master_clock [get_clocks $::env(CLOCK_PORT)] -combinational $ref_clk_tx1_mux_pin -add
create_generated_clock -name $::env(OUTPUT_CLOCK_2) -source [get_ports $::env(CLOCK_PORT)] -master_clock [get_clocks $::env(CLOCK_PORT)] -combinational $ref_clk_tx2_mux_pin -add

set_propagated_clock [all_clocks]

report_clock_properties [all_clocks]

set ::env(PHY_RX_PINS) {ui_in[0] ui_in[1] ui_in[2] ui_in[3] ui_in[4] ui_in[5] ui_in[6] ui_in[7] uio_in[0] uio_in[1] uio_in[2]}
set ::env(PHY_TX0_PINS) {uo_out[0] uo_out[1] uo_out[2]}
set ::env(PHY_TX1_PINS) {uo_out[5] uo_out[6] uo_out[7]}
set ::env(PHY_TX2_PINS) {uio_out[5] uio_out[6] uio_out[7]}

read_sdc $::env(DESIGN_DIR)/lan8720a.sdc
