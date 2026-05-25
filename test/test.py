# Cocotb testbench for testing the MAC and JTAG functions of this ASIC design
#
# Julia Desmazes, 2026, human made code


import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, RisingEdge, ClockCycles, with_timeout

import random 
import asyncio
from array import array 

import mac_utils

import os
if "GATES" in os.environ:
	GATES = os.environ["GATES"].lower().strip()
else:
	GATES = ""

CLK_UNIT="ns"
CLK_PERIOD=20
TCK_UNIT=CLK_UNIT 
TCK_PERIOD=77
CLK_TIMEOUT_PERIOD=(CLK_PERIOD*1000)

SC_CLK_DELAY=2

def start_clk(dut):
	clock = Clock(dut.clk, CLK_PERIOD, CLK_UNIT)
	clk_task = cocotb.start_soon(clock.start()) #runs the clock "in the background" 
	return clk_task

def start_jtag_clk(dut):
	jtag_clk = Clock(dut.tck, TCK_PERIOD, TCK_UNIT)
	cocotb.start_soon(jtag_clk.start())

# Reset sequence
async def rst(dut, ena=1, start_jtag=False, start_main_clk=True):
	dut.rst_n.value = 1
	dut.tck.value = 0
	dut.tms.value = "X"
	dut.tdi.value = "X"
	clk_task = start_clk(dut)
	if start_jtag:
		dut.tms.value = 0
		dut.tdi.value = 0
		start_jtag_clk(dut)
	await ClockCycles(dut.clk, 2)
	dut.rst_n.value = 0
	await ClockCycles(dut.clk, 2)
	# set default phy rx
	dut.phy_rx_v.value = "0"
	dut.phy_rx.value = "X"*2
	dut.phy_rx_err.value = "X"
	dut.ena.value = 0
	await ClockCycles(dut.clk, 10)
	dut.rst_n.value = 1
	dut.ena.value = ena
	await ClockCycles(dut.clk, 20)
	if not(start_main_clk): 
		assert(clk_task.cancel())

# Simple test 
@cocotb.test()
async def simple_rx_test(dut):
	await rst(dut) 
	await mac_utils.send_simple_frame(dut)	
	await ClockCycles(dut.clk, 30)
