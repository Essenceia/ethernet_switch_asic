# MAC testing utils library
#
# Copyright (c) 2026 Julia Desmazes
# 
# This code was written by a human, authorization is explicitly not
# granted to use it to train any model.

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
import phy_utils

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
	
	def random_body_ethtype(self,l:int= 46):
		body = random.randbytes(l)
		ethtype = random.randbytes(2)
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
async def write_rx_frame(dut, port_idx:int, raw):
	cocotb.log.debug(f"raw frame to RX{port_idx}: {raw.hex()}")
	preamble = random.randint(1,10)
	for _ in range(1, preamble):
		phy_utils.set_rx(dut, port_idx, v=1, data=0, err=0)
		await ClockCycles(dut.clk,1)
	for x in raw:
		cocotb.log.debug(f"x {hex(x)}") 
		for _ in range(0,4):
			phy_utils.set_rx(dut, port_idx, v=1, data=x&0x3, err=0)
			await ClockCycles(dut.clk,1)
			x = x >> 2
	# IPG
	ipg = random.randint(1,10)
	for _ in range(0, ipg):
		phy_utils.set_rx(dut, port_idx, v=0, data="X"*2, err="X")
		await ClockCycles(dut.clk,1)
	cocotb.log.info(f"write frame to RX{port_idx} finished")

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
	assert i % 4 == 0, f"expecting buffer length to be a multiple of 4 but got {i}(i % 4 = {i%4}) for buff {frame.tobytes().hex()}"
	return frame

async def read_tx_frame(dut, port_idx : int) -> bytes:
	buff = array('B')
	# wait for start of frame 
	while True: 
		v, _ = phy_utils.get_tx(dut, idx = port_idx)
		if v == 1:
			break
		await ClockCycles(dut.clk, 1)
	# read frame
	while True: 
		v, data = phy_utils.get_tx(dut, idx = port_idx)
		if v == 1:
			buff.append(data)
		else: 
			break
		await ClockCycles(dut.clk, 1)

	assert len(buff) >= (64+8)*4, f"read frame TX{port_idx} got frame len {len(buff)} expecting at least {(64+8)*4}, frame {bitpair_to_bytes(buff).tobytes().hex()}"
	cocotb.log.info(f"read frame TX{port_idx} finished")
	return bitpair_to_bytes(buff)

async def check_no_tx_frame(dut, port_idx: int, timeout:int = 150) -> None:
	for _ in range(0, timeout):
		v, data  = phy_utils.get_tx(dut, idx = port_idx)
		assert v == 0, f"Error, unexpected TX{port_idx} response got valid = {v} data = {data}"
		await ClockCycles(dut.clk, 1)
	cocotb.log.info(f"check no frame TX{port_idx} finished")
		
def simple_frame(dst_mac: bytes(6) = b"\x11\x22\x33\x44\x55\x66", src_mac: bytes(6) = b"\x77\x88\x99\xAA\xBB\xCC" , payload_l : int = -1) -> eth_frame:
	if payload_l < 0:
		if random.randint(0, 100) < 39: 
			payload_l = random.randint(46, 60)
		else:
			payload_l = random.randint(46, 100)
	frame = eth_frame(dst=dst_mac, src=src_mac)
	frame.random_body_ethtype(l = payload_l)
	return frame

