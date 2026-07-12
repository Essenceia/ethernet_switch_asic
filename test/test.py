# Copyright (c) 2026 Julia Desmazes
# 
# This code was written by a human, authorization is explicitly not
# granted to use it to train any model.

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, RisingEdge, ClockCycles, with_timeout

import random 
import asyncio
import time

import switch_tests
import phy_utils

from array import array 

import os

GATES = os.getenv("GATES", False)

CLK_UNIT="ns"
CLK_PERIOD=20
RST_CYCLES=200

def start_clk(dut):
	clock = Clock(dut.clk, CLK_PERIOD, CLK_UNIT)
	clk_task = cocotb.start_soon(clock.start()) #runs the clock "in the background" 
	return clk_task

def set_random_seed():
	if "SEED" in os.environ:
		seed = int(os.environ["SEED"].lower().strip())
	else:
		seed = time.time_ns()
	cocotb.log.info(f"random seed {seed}")
	random.seed(seed)

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

		
# Simple broadcast test with enogth gap between rx and tx
# packets such that all broadcast TXs are free 
@cocotb.test()
async def simple_broadcast_test(dut):
	set_random_seed()
	await rst(dut) 
	await switch_tests.simple_unicast_test_sequence(dut)

@cocotb.test()
async def checking_broadcast_test(dut):
	set_random_seed()
	await rst(dut)
	await switch_tests.checking_broadcast_test_sequence(dut)

@cocotb.test()
async def simple_unicast_test(dut):
	set_random_seed()
	await rst(dut) 
	await switch_tests.simple_unicast_test_sequence(dut)

@cocotb.test()
async def table_entry_expire_test(dut):
	set_random_seed()
	await rst(dut) 
	await switch_tests.table_entry_expire_test_sequence(dut)

@cocotb.test()
async def table_multialloc_test(dut): 
	set_random_seed()
	await rst(dut) 
	await switch_tests.table_multialloc_test_sequence(dut)

@cocotb.test()
async def table_realloc_test(dut): 
	set_random_seed()
	await rst(dut) 
	await switch_tests.table_realloc_test_sequence(dut)

# sim only tests: need accurate tracking of entry liveness to prevent fausle failes
@cocotb.test(skip=True if GATES == "yes" else False)
async def table_stress_read(dut):
	set_random_seed()
	await rst(dut)
	await switch_tests.table_stress_read_sequence(dut)

@cocotb.test()
async def no_rebroadcsat_on_incomming_test(dut):
	set_random_seed()
	await rst(dut)
	await switch_tests.no_rebroadcsat_on_incomming_test_sequence(dut)

@cocotb.test()
async def close_rx_packets_test(dut):
	set_random_seed()
	await rst(dut)
	await switch_tests.close_rx_packets_test_sequence(dut)

