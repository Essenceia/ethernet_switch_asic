set project_dir [lindex $argv 0]
set project_name [lindex $argv 1]
set src_path [lindex $argv 2]
if { $argc > 3 } {
	set use_gates [lindex $argv 3]
	set gate_nl [lindex $argv 4] 
	set gate_lib [lindex $argv 5] 
} else {
	set use_gates false
}

puts "Creating project $project_name at path [pwd]/$project_dir"
create_project -part xc7a35ticpg236-1L -force $project_name $project_dir

# load src
read_verilog -sv [glob *.v]

if { $use_gates } {
	set_property verilog_define USE_GATE_NL=1 [current_fileset]
	read_verilog -sv $gate_nl
	read_verilog -sv $gate_lib
} else {
	puts "Reading system verilog sources src:'$src_path'"
	read_verilog -sv [glob -directory $src_path *.v]
}
read_xdc [glob *.xdc]

# to save the hastle of calling synth with top specified
set_property top emulator [current_fileset]

close_project
exit 0
