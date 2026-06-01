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

import crc_utils 

APP_ETHTYPE = b"\x88\xB5"
DEVICE_MAC = b"\x00\x90\xCF\x00\xBE\xEF"

class dot1q(NamedTuple):
	tpid: bytes = b'\x81\x00'
	tci: bytes = bytes(2)
	
class MAC_header(NamedTuple):
	dst : bytes = bytes(6)	
	src : bytes = bytes(6)
	vlan_tag: Optional[dot1q] = None
	ethtype: bytes = bytes(2)

	def raw(self):
		r = bytearray()
		r+= self.dst
		r+= self.src
		if self.vlan_tag is not None:
			r += self.vlan_tag.tpid
			r += self.vlan_tag.tci
		r+= self.ethtype
		return r

@dataclass
class eth_frame:
	sfd: bytes = b'\xab'
	header: MAC_header = MAC_header()
	body: bytes = bytes(48)
	fcs: bytes = b'\xff\xff\xff\xff'
	
	def random_body(self, ethtype=b'\x88\xB5'):
		l = random.randint(48,60)
		body = bytearray(0)
		for i in range(0,l):
			body.append(random.randint(0,255))
		self.set_payload(body, ethtype)
		

	def set_payload(self, payload, ethtype=b'\x88\xB5'):
		self.body = payload
		self.header = self.header._replace(ethtype = ethtype)

	def __init__(self, dst, src, vlan_tag = None):
		if self.header.vlan_tag is not None: 
			self.header = MAC_header(dst,src,vlan_tag = dot1q(tci=vlan_tag))
		else:
			self.header = MAC_header(dst, src) 

	def raw(self):
		r = bytearray()
		r += self.header.raw()
		r += self.body
		r += crc_utils.calc_fcs(r)
		r = self.sfd + r
		return r

async def phy_stream_frame(dut, raw):
	cocotb.log.info(f"raw frame {raw.hex()}")
	preamble = random.randint(1,10)
	dut.phy_rx_err.value = 0
	for _ in range(1, preamble):
		dut.phy_rx_v.value = 1
		dut.phy_rx.value = 0
		await ClockCycles(dut.clk,1)
	for x in raw:
		cocotb.log.debug(f"x {hex(x)}") 
		for _ in range(0,4):
			dut.phy_rx_v.value = 1
			dut.phy_rx.value = (x & 0xc0) >> 6
			await ClockCycles(dut.clk,1)
			cocotb.log.debug(f"{dut.phy_rx.value}")
			x = x << 2
	# IPG
	ipg = random.randint(1,10)
	for _ in range(0, ipg):
		dut.phy_rx_v.value = 0
		dut.phy_rx_err.value = "X"
		dut.phy_rx.value = "X"*2
		await ClockCycles(dut.clk,1)

# convert from byte array where data is stored in the 2 lower bits 
# to a real byte array 
def bitpair_to_bytes(buff):
	frame = array('B')
	tmp = 0
	i = 0
	for b in buff: 
		tmp |= b << 2*(i%4)
		cocotb.log.info(f"tmp {hex(tmp)} b{hex(b)}") 
		i = i+1
		if ( i % 4 == 0): 
			cocotb.log.info(f"i {int((i-1)/4)} tmp {hex(tmp)}") 
			frame.append(tmp)
			tmp = 0 

	cocotb.log.info(f"tx frame {frame.tobytes().hex()} ({len(frame)})") 
	cocotb.log.info(f"i {i}") 
	assert(i % 4 == 0)
	return frame

async def read_tx_frame(dut):
	buff = array('B') 
	while( dut.phy_tx_v.value != 1):
		await ClockCycles(dut.clk, 1)
	while (dut.phy_tx_v.value == 1):
		buff.append(dut.phy_tx.value)
		await ClockCycles(dut.clk, 1)
	return bitpair_to_bytes(buff)

def raw_tx_to_eth_frame(raw):
	pass	
	
async def send_simple_frame(dut):
	random.seed(0)
	# group dst address
	frame = eth_frame(DEVICE_MAC, b"\xFF\xFF\x00\xFF\x00\xFF")
	frame.random_body(ethtype = APP_ETHTYPE)
	read_tx_thread = cocotb.start_soon(read_tx_frame(dut))
	await phy_stream_frame(dut,frame.raw())
	tx_frame = await read_tx_thread

		
