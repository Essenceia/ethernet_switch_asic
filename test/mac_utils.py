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
import app_utils
import conf_utils

APP_ETHTYPE = b"\x88\xB5"
CONF_ETHTYPE = b"\x88\xB6"
DEFAULT_DEVICE_MAC = b"\x00\x90\xCF\x00\xBE\xEF"
DEFAULT_VID = b"\x0D\xAD"
VID_MASK = b"\x0F\xFF"
PREAMBLE=b"\x55\x55\x55\x55\x55\x55\x55"

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
		# big endian 
		r+= self.dst 
		r+= self.src
		if self.vlan_tag is not None:
			r += self.vlan_tag.tpid
			r += self.vlan_tag.tci
		r+= self.ethtype
		return r

@dataclass
class eth_frame:
	sfd: bytes = b'\xd5'
	header: MAC_header = MAC_header()
	body: bytes = bytes(46)
	fcs: bytes = b'\xff\xff\xff\xff'
	
	def random_body(self, ethtype : bytes(2) =b'\x88\xB5', l:int= 46):
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

	def raw(self, is_rmii_tx:bool = False):
		r = bytearray()
		r += self.header.raw()
		r += self.body
		r += crc_utils.calc_fcs(r)
		r = self.sfd + r
		if is_rmii_tx:
			r = bytes(PREAMBLE)	+ r
		return r

# lsbit first MSByte first

async def phy_stream_frame(dut, raw):
	cocotb.log.debug(f"raw frame {raw.hex()}")
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
			dut.phy_rx.value = x & 0x3
			await ClockCycles(dut.clk,1)
			cocotb.log.debug(f"{dut.phy_rx.value}")
			x = x >> 2
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
		cocotb.log.debug(f"tmp {hex(tmp)} b{hex(b)}") 
		i = i+1
		if ( i % 4 == 0): 
			cocotb.log.debug(f"i {int((i-1)/4)} tmp {hex(tmp)}") 
			frame.append(tmp)
			tmp = 0 

	cocotb.log.debug(f"tx frame {frame.tobytes().hex()} ({len(frame)})") 
	cocotb.log.debug(f"i {i}") 
	assert(i % 4 == 0)
	return frame

async def read_tx_frame(dut) -> bytes:
	buff = array('B') 
	while( dut.phy_tx_v.value != 1):
		await ClockCycles(dut.clk, 1)
	while (dut.phy_tx_v.value == 1):
		buff.append(dut.phy_tx.value)
		await ClockCycles(dut.clk, 1)
	return bitpair_to_bytes(buff)

async def check_no_tx_frame(dut, timeout:int = 150) -> None:
	for _ in range(0, timeout): 
		if (dut.phy_tx_v.value == 1):
			cocotb.log.error("Error, unexpected tx response")
			assert(0)
		await ClockCycles(dut.clk, 1)
		
# { expect result boolean, result }
def expected_response(req: eth_frame) -> tuple[bool, eth_frame]:
	tx_sent = False
	if (req.header.dst == DEFAULT_DEVICE_MAC) and(req.header.ethtype == APP_ETHTYPE): 
		tx_sent = True
	if req.header.vlan_tag is not None: 	
		if (req.header.vlan_tag.tci & VID_MASK) != DEFAULT_VID:
			tx_sent = False
	resp = eth_frame(dst=req.header.src, src=req.header.dst)
	resp.set_payload(app_utils.layer3_app(req.body), APP_ETHTYPE)
	return tx_sent, resp
		
def simple_frame() -> eth_frame:
	# group dst address
	frame = eth_frame(dst=DEFAULT_DEVICE_MAC, src=b"\x00\xF0\x00\xFF\x00\xFF")
	frame.random_body(ethtype = APP_ETHTYPE)
	return frame

def test_filtered_packets() -> eth_frame:
	accepted_pkt = simple_frame()
	dst_mac = DEFAULT_DEVICE_MAC
	src_mac = random.randbytes(6)
	ethtype = APP_ETHTYPE
	if (random.randint(0,100) < 10):
		dst_mac = random.randbytes(6)
	if (random.randint(0,100) < 10):
		ethtype = random.randbytes(2)
	frame = eth_frame(dst = dst_mac, src = src_mac)
	frame.random_body(ethtype = ethtype)
	return frame

def simple_config(dst_mac : bytes(6) = DEFAULT_DEVICE_MAC) -> eth_frame:
	frame = eth_frame(dst=dst_mac, src=b"\x00\xF0\x00\xFF\x00\xFF")
	conf_pkt = conf_utils.config_payload()
	frame.set_payload(payload = conf_pkt.raw(), ethtype = CONF_ETHTYPE)
	return frame
