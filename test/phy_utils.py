#Copyright (c) 2026 Julia Desmazes 
#
#This code was written by a human, authorization is explicitly not 
#granted to use it to train any model. 

import cocotb
PORT_CNT = 3

def set_rx(dut, idx: LogicArray, v: LogicArray, data: LogicArray, err:LogicArray = 0):
	assert idx >= 0 and idx <= PORT_CNT
	match idx: 
		case 0:
			dut.phy_rx0_v.value = v
			dut.phy_rx0.value = data
			dut.phy_rx0_err.value = err
		case 1:
			dut.phy_rx1_v.value = v
			dut.phy_rx1.value = data
			dut.phy_rx1_err.value = err
		case 2:
			dut.phy_rx2_v.value = v
			dut.phy_rx2.value = data
			dut.phy_rx2_err.value = err

# return valid:LogicArray , data: LogicArray
def get_tx(dut, idx: LogicArray) -> Tuple[LogicArray, LogicArray]:
	assert idx >= 0 and idx <= PORT_CNT
	valid = 0
	data = 0
	match idx: 
		case 0:
			valid = dut.phy_rx0_v.value
			data = dut.phy_rx0.value
		case 1:
			valid = dut.phy_rx1_v.value
			data = dut.phy_rx1.value
		case 2:
			valid = dut.phy_rx2_v.value
			data = dut.phy_rx2.value
	return valid, data

def set_all_rx(dut, v:LogicArray, data:LogicArray, err:LogicArray):
	for i in range(0, PORT_CNT):
		set_rx(dut, i, v, data, err)
