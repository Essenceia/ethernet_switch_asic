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

from array import array 

import mac_utils
import phy_utils
import table_utils

import os

if "GATES" in os.environ:
	GATES = os.environ["GATES"].lower().strip()
else:
	GATES = ""

if "TEST_ITER" in os.environ:
	TEST_ITER = int(os.environ["TEST_ITER"].lower().strip())
else:
	TEST_ITER = 10


CLK_UNIT="ns"
CLK_PERIOD=20
RST_CYCLES=200
CLK_TIMEOUT_PERIOD = 5000

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
			
			try:
				tx_frame = await with_timeout( tx_thread, CLK_TIMEOUT_PERIOD, CLK_UNIT) 
			except TimeoutError:
				cocotb.log.error(f"Timeout reading TX{i}")
				assert(0)
			
			# compare gotten and expected
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
	set_random_seed()
	await rst(dut) 
	for _ in range(0, TEST_ITER):
		port_idx = random.randrange(0,phy_utils.PORT_CNT)
		await send_frame(dut, port_idx, mac_utils.simple_frame(dst_mac = table_utils.random_broadcast_mac()))
		# respect IPG	
		await ClockCycles(dut.clk, 2*8*4 + 1) 
	await ClockCycles(dut.clk, 10)

async def check_broadcast(dut, src_port:int, src_mac: bytes(6), dst_mac: bytes(6)):
	cocotb.log.info(f"check broadcast, RX{src_port} (dst_mac:{dst_mac.hex()} src_mac:{src_mac.hex()})") 
	rx_frames = {}
	tx_frames = {}
	for i in range(0, phy_utils.PORT_CNT):
		if i == src_port:
			rx_frames[i] = mac_utils.simple_frame(src_mac = src_mac, dst_mac = dst_mac)
		else:
			rx_frames[i] = None
	for i in range(0, phy_utils.PORT_CNT):
		if i == src_port: 
			tx_frames[i] = None
		else: 
			tx_frames[i] = rx_frames[src_port]	
	await send_and_check_frames(dut, rx_frames, tx_frames)

@cocotb.test()
async def checking_broadcast_test(dut):
	set_random_seed()
	rx_frames = {}
	tx_frames = {}
	await rst(dut) 
	for _ in range(0, TEST_ITER):
		port_idx = random.randrange(0,phy_utils.PORT_CNT)
		src_mac = table_utils.random_unicast_mac()
		dst_mac = table_utils.random_broadcast_mac()
		await check_broadcast(dut, src_port=port_idx, src_mac=src_mac, dst_mac = dst_mac)
		# respect IPG	
		await ClockCycles(dut.clk, 2*8*4 + 1) 
	await ClockCycles(dut.clk, 10)

async def check_unicast(dut, src_port:int, dst_port:int, dst_mac: bytes(6), src_mac: bytes(6)):
	cocotb.log.info(f"check unicast, RX{src_port}->TX{dst_port} (dst_mac:{dst_mac.hex()} src_mac:{src_mac.hex()})") 
	rx_frames = {}
	tx_frames = {}
	for i in range(0, phy_utils.PORT_CNT):
		if i == src_port:
			rx_frames[i] = mac_utils.simple_frame(dst_mac = dst_mac, src_mac = src_mac)
		else:
			rx_frames[i] = None
	for i in range(0, phy_utils.PORT_CNT):
		if i == dst_port: 
			tx_frames[i] = rx_frames[src_port]	
		else: 
			tx_frames[i] = None
	await send_and_check_frames(dut, rx_frames, tx_frames)


@cocotb.test()
async def simple_unicast_test(dut):
	set_random_seed()
	await rst(dut) 
	target_mac =table_utils.random_unicast_mac() 
	dst_mac =table_utils.random_unicast_mac() 
	target_port = random.randrange(0,phy_utils.PORT_CNT)
	cocotb.log.info(f"unicast target src mac {target_mac.hex()} port RX{target_port}")
	# send packet with source, table is empty, should be broadcasted
	await check_broadcast(dut, src_port = target_port, src_mac = target_mac, dst_mac = dst_mac)

	# send packets to be routed to original port 
	for _ in range(0, 4): 
		pkt_port = phy_utils.random_exclude_port(target_port) 		
		ignored_mac = table_utils.random_broadcast_mac() # using broadcast mac to prevent it being written to the table
		cocotb.log.info(f"ignored src mac {ignored_mac.hex()}")
		await check_unicast(dut, src_port = pkt_port, dst_port = target_port, dst_mac = target_mac, src_mac = ignored_mac)
		# respect IPG	
		await ClockCycles(dut.clk, 2*8*4 + 1)
	if GATES == "": 
		await ClockCycles(dut.clk, table_utils.ENTRY_EXPIERY_TIMEOUT_SHORT)
		
		# check entry has expired
		pkt_port = phy_utils.random_exclude_port(target_port) 		
		await check_broadcast(dut, src_port = pkt_port, src_mac = target_mac, dst_mac = dst_mac)

@cocotb.test()
async def table_entry_expire_test(dut):
	set_random_seed()
	await rst(dut) 
	src_mac = table_utils.random_unicast_mac() 
	cocotb.log.info(f"unicast src mac {src_mac.hex()}")
	# send packet with source, table is empty, should be broadcasted
	origin_port = random.randrange(0, phy_utils.PORT_CNT)
	await check_broadcast(dut, src_port = origin_port, src_mac = src_mac, dst_mac = table_utils.random_broadcast_mac())
	if GATES == "": #expire time change between gl and pure sim
		cocotb.log.info(f"wait for expire {table_utils.ENTRY_EXPIERY_TIMEOUT}")
		await ClockCycles(dut.clk, table_utils.ENTRY_EXPIERY_TIMEOUT)
		await check_broadcast(dut, src_port = phy_utils.random_exclude_port(origin_port), src_mac = table_utils.random_unicast_mac(), dst_mac = src_mac)

@cocotb.test()
async def table_multialloc_test(dut): 
	set_random_seed()
	await rst(dut) 
	for i in range(0, TEST_ITER): 
		dst_mac = table_utils.random_broadcast_mac() 
		src_mac = table_utils.random_unicast_mac() 
		origin_port = random.randrange(0, phy_utils.PORT_CNT)
		await check_broadcast(dut, src_port = origin_port, src_mac = src_mac, dst_mac = dst_mac)
		# IPG
		await ClockCycles(dut.clk, 2*8*4 + 1)
		# check entry is properly allocated
		await check_unicast(dut, src_port = phy_utils.random_exclude_port(origin_port), dst_port = origin_port, dst_mac = src_mac, src_mac = table_utils.random_unicast_mac())
		if GATES == "":
			if 2*(i+1) >= table_utils.ENTRY_NUM: 
				assert dut.m_dut.m_switch.m_lookup.m_dispatcher.m_table.cocotb_nobody_is_dead.value == 1, f"Unexpacted invalid table entry"
			else:
				alloc_cnt =  dut.m_dut.m_switch.m_lookup.m_dispatcher.m_table.cocotb_entry_alloc_cnt.value
				assert alloc_cnt == 2*(i+1), f"Expecting {i} allocated table entries got {alloc_cnt}"
		# IPG
		await ClockCycles(dut.clk, 2*8*4 + 1)

@cocotb.test()
async def table_realloc_test(dut): 
	set_random_seed()
	await rst(dut) 
	src_mac = table_utils.random_unicast_mac() 
	for i in range(0, TEST_ITER): 
		dst_mac = table_utils.random_broadcast_mac() 
		origin_port = random.randrange(0, phy_utils.PORT_CNT)
		await check_broadcast(dut, src_port = origin_port, src_mac = src_mac, dst_mac = dst_mac)
		# IPG
		await ClockCycles(dut.clk, 2*8*4 + 1)
		if GATES == "": 
			assert dut.m_dut.m_switch.m_lookup.m_dispatcher.m_table.cocotb_nobody_is_dead.value == 0, f"Unexpacted multiple allocated table entries"
			assert dut.m_dut.m_switch.m_lookup.m_dispatcher.m_table.cocotb_entry_alloc_cnt.value == 1, f"Expecting a single allocated table entry"

# sim only tests
@cocotb.test()
async def table_stress_read(dut):
	set_random_seed()
	await rst(dut)
	for _ in range(0, TEST_ITER*5):
		wr_credits = table_utils.ENTRY_NUM - 1
		table_utils.clear_seen_src_mac()
		# write an entry
		rd_port = random.randrange(0, phy_utils.PORT_CNT)
		rd_mac = table_utils.random_unicast_mac()
		await check_broadcast(dut, src_port = rd_port, src_mac = rd_mac, dst_mac = table_utils.random_unicast_mac())
		table_utils.add_seen_src_mac(rd_mac, rd_port)	
		await ClockCycles(dut.clk, 2*8*4 + 1) 
		for _ in range(0, 4):
			# random write if credits available
			if random.randrange(0,100) > 20 and wr_credits > 0:
				new_src_mac = table_utils.random_unicast_mac()
				new_src_port = random.randrange(0, phy_utils.PORT_CNT)
				await check_broadcast(dut, src_port = new_src_port, src_mac = new_src_mac, dst_mac = table_utils.random_unicast_mac())
				wr_credits = wr_credits - 1	
				table_utils.add_seen_src_mac(new_src_mac, new_src_port)
				cocotb.log.info(f"add seen mac:{new_src_mac.hex()} port:{new_src_port}")
				await ClockCycles(dut.clk, 2*8*4 + 1) 
			# check entry read 
			known_sender_mac, known_sender_port = table_utils.random_seen_src_mac(dut, GATES)
			cocotb.log.info(f"know mac:{known_sender_mac.hex()} port:{known_sender_port}")
			if table_utils.seen_src_mac_cnt(dut, GATES) > 1:
				while True:
					src_mac, _ = table_utils.random_seen_src_mac(dut, GATES)
					if src_mac != known_sender_mac :
						break
			else:
				src_mac = table_utils.random_unicast_mac()
			src_port = phy_utils.random_exclude_port(known_sender_port) # update port if already allocated
			await check_unicast(dut, src_port = src_port, dst_port = known_sender_port, dst_mac = known_sender_mac, src_mac = src_mac)
			table_utils.add_seen_src_mac(src_mac, src_port)
			cocotb.log.info(f"add seen bis mac:{src_mac.hex()} port:{src_port}")
			await ClockCycles(dut.clk, 2*8*4 + 1) 
			
		







