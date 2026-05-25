# MAC testing utils library
#
# Julia Desmazes, 2026, human made code
import struct
import dataclasses
from dataclasses import dataclass

import cocotb
from cocotb.triggers import ClockCycles
import random 
from array import array
from typing import NamedTuple, Optional

class dot1q(NamedTuple):
	tpid: bytes = b'\x81\x00'
	tci: bytes = bytes(2)
	
class MAC_header(NamedTuple):
	dst : bytes = bytes(6)	
	src : bytes = bytes(6)
	vlan_tag: Optional[dot1q] = None
	ethtype: bytes = bytes(2)

@dataclass
class eth_frame:
	sfd: bytes = b'\xab'
	header: MAC_header = MAC_header()
	body: bytes = bytes(48)
	fcs: bytes = b'\xff\xff\xff\xff'
	
	def random_body(self):
		l = random.randint(48,2000)
		body = bytes(0)
		for i in range(0,l):
			body.append(random.randint(0,255))
		self.header = self.header._replace(ethtype = struct.pack('!p', l))
 
	def __init__(self, dst, src, vlan_tag = None):
		if vlan_tag is not None: 
			self.header = MAC_header(dst,src,vlan_tag = dot1q(tci=vlan_tag))
		else:
			self.header = MAC_header(dst, src) 
	
	def calc_fcs(self):
		pass # TODO

	def raw(self):
		self.calc_fcs()
		return struct.pack('!pppp', *dataclasses.astuple(self))

async def phy_stream_frame(dut, raw):
	preamble = random.randinit(1,10)
	dut.phy_rx_err.value = 0
	for _ in range(1, preamble):
		dut.phy_rx_v.value = 1
		dut.phy_rx.value = 0
		await ClockCycles(dut.clk,1)
	for x in raw: 
		for _ in range(0,4):
			dut.phy_rx_v.value = 1
			dut.phy_rx.value = x & 0x03
			x = x >> 2
			await ClockCycles(dut.clk,1)
	# IPG
	ipg = random.randint(1,10)
	for _ in range(0, ipg):
		dut.phy_rx_v.value = 0
		await ClockCycles(dut.clk,1)
	
async def send_simple_frame(dut):
	frame = eth_frame(b"\xAA\xBB\xCC\xDD\xEE\xFF",b"\x00\x11\x22\x33\x44\x55")
	phy_stream_frame(dut,frame.raw())
