# Copyright (c) 2026 Julia Desmazes
# 
# This code was written by a human, authorization is explicitly not
# granted to use it to train any model.

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, RisingEdge, ClockCycles, with_timeout

import random 
import asyncio
from array import array 

import mac_utils
import phy_utils
import table_utils

import os
if "GATES" in os.environ:
	GATES = os.environ["GATES"].lower().strip()
else:
	GATES = ""

CLK_UNIT="ns"
CLK_PERIOD=20
RST_CYCLES=200

def start_clk(dut):
	clock = Clock(dut.clk, CLK_PERIOD, CLK_UNIT)
	clk_task = cocotb.start_soon(clock.start()) #runs the clock "in the background" 
	return clk_task


# Reset sequence
async def rst(dut, ena=1 ):
	dut.rst_n.value = 0
	dut.tx_phase.value = 0
	clk_task = start_clk(dut)
	await ClockCycles(dut.clk, 2)
	# set default phy rx
	phy_utils.set_all_rx(dut, 0, "X"*2, "X")
	dut.ena.value = 0
	await ClockCycles(dut.clk, RST_CYCLES)
	dut.rst_n.value = 1
	dut.ena.value = ena
	await ClockCycles(dut.clk, 20)

# send only, do not check for response
async def send_frame(dut, port_idx:int, rx: mac_utils.eth_frame):
	await mac_utils.write_rx_frame(dut, port_idx, rx.raw())

async def send_and_check_frames(dut, rx: {int, mac_utils.eth_frame}, tx: {int, mac_utils.eth_frame}):
	write_rx_thread = []
	read_tx_thread = []
	for i in range(0, phy_utils.PORT_CNT):
		if rx[i] is not None:
			write_rx_thread.append(cocotb.start_soon(mac_utils.write_rx_frame(dut, port_idx = i, raw = rx[i].raw())))
		if tx[i] is not None:
			read_tx_thread.append(cocotb.start_soon(mac_utils.read_tx_frame(dut, port_idx = i)))
		else:		
			read_tx_thread.append(cocotb.start_soon(mac_utils.check_no_tx_frame(dut, port_idx = i)))
	# send rx
	for rx_thread in write_rx_thread: 
		await rx_thread
	# wait for tx 
	for i in range(0, phy_utils.PORT_CNT):
		tx_thread = read_tx_thread[i]
		if tx[i] is not None:
			# compare gotten and expected
			tx_frame = await tx_thread
			tx_raw = tx[i].raw(is_rmii_tx = True)
			expected = tx_raw.hex()
			gotten = tx_frame.tobytes().hex()
			cocotb.log.info(f"TX{i} {gotten}")
			if (expected != gotten): 
				cocotb.log.error(f"Error, missmatch between expected and gotten TX{i} ethernet frame\nexp {expected}\ngot {gotten}")
				debug_string = 4*" "
				for (e, g) in zip(expected, gotten):
					debug_string += "^" if (e != g) else " "
				cocotb.log.error(debug_string)
				assert(0)
		else:
			await tx_thread
			
# Simple broadcast test with enogth gap between rx and tx
# packets such that all broadcast TXs are free 
@cocotb.test()
async def simple_broadcast_test(dut):
	random.seed(0)
	await rst(dut) 
	for _ in range(0, 10):
		port_idx = random.randrange(0,phy_utils.PORT_CNT)
		await send_frame(dut, port_idx, mac_utils.simple_frame(src_mac = table_utils.random_broadcast_mac()))
		# respect IPG	
		await ClockCycles(dut.clk, 2*8*4 + 1) 
	await ClockCycles(dut.clk, 10)

@cocotb.test()
async def checking_broadcast_test(dut):
	random.seed(0)
	rx_frames = {}
	tx_frames = {}
	await rst(dut) 
	for _ in range(0, 10):
		port_idx = random.randrange(0,phy_utils.PORT_CNT)
		for i in range(0, phy_utils.PORT_CNT):
			if i == port_idx:
				rx_frames[i] = mac_utils.simple_frame(src_mac = table_utils.random_broadcast_mac())
			else:
				rx_frames[i] = None
		for i in range(0, phy_utils.PORT_CNT):
			if i == port_idx: 
				tx_frames[i] = None
			else: 
				tx_frames[i] = rx_frames[port_idx]	
		await send_and_check_frames(dut, rx_frames, tx_frames)
		# respect IPG	
		await ClockCycles(dut.clk, 2*8*4 + 1) 
	await ClockCycles(dut.clk, 10)

@cocotb.test()
async def simple_unicast_test(dut):
	random.seed(0)
	await rst(dut) 
	for _ in range(0, 10):
		port_idx = random.randrange(0,phy_utils.PORT_CNT)
		await send_frame(dut, port_idx, mac_utils.simple_frame(src_mac = table_utils.random_unicast_mac()))
		# respect IPG	
		await ClockCycles(dut.clk, 2*8*4 + 1) 
	await ClockCycles(dut.clk, 10)
