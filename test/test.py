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

# send only, used to test config frames where no response is expected
async def send_frame(dut, rx: eth_frame):
	await mac_utils.phy_stream_frame(dut, rx.raw())

async def send_and_check_frames(dut,rx : eth_frame):
	tx_sent, tx = mac_utils.expected_response(rx)
	if tx_sent: 
		read_tx_thread = cocotb.start_soon(mac_utils.read_tx_frame(dut))
	else:
		read_tx_thread = cocotb.start_soon(mac_utils.check_no_tx_frame(dut))
	await mac_utils.phy_stream_frame(dut,rx.raw())
	tx_frame = await read_tx_thread
	if tx_sent:
		tx_raw = tx.raw(is_rmii_tx = True)
		expected = tx_raw.hex()
		gotten = tx_frame.tobytes().hex()
		if (expected != gotten): 
			cocotb.log.error(f"Error, missmatch between expected and gotten tx ethernet frame\nexp {expected}\ngot {gotten}")
			debug_string = 4*" "
			for (e, g) in zip(expected, gotten):
				debug_string += "^" if (e != g) else " "
			cocotb.log.error(debug_string)
			assert(0)
	# IPG, but shorter
	await ClockCycles(dut.clk, random.randint(1, 10))
	
# Simple test 
@cocotb.test()
async def simple_rx_test(dut):
	random.seed(0)
	await rst(dut) 
	for _ in range(0, 10):
		await send_and_check_frames(dut, mac_utils.simple_frame())	
	await ClockCycles(dut.clk, 10)

@cocotb.test()
async def filter_rx_test(dut):
	await rst(dut)
	for _ in range(0,10):
		await send_and_check_frames(dut, mac_utils.test_filtered_packets())
	await ClockCycles(dut.clk, 10)

@cocotb.test()
async def update_eth_config(dut):
	await rst(dut)
	await send_frame(dut, mac_utils.simple_config())
