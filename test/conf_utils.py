# Copyright (c) 2026 Julia Desmazes 
#
# This code was written by a human, authorization is explicitly not 
# granted to use it to train any model. 

import random

class config_payload():
	addr: bytes(6)
	vid: bytes(2) #bottom 12 bits
	phase: bytes(1) # bottom 1 bit
	padding: bytearray(37)

	def random(self):
		self.addr = random.randbytes(6)
		self.vid   = random.randbytes(2)
		self.phase = random.randbytes(1)
		self.padding = bytearray(36)#random.randbytes(37)
		self.padding.append(255)

	def set(self, addr: bytes(6), vid: bytes(2), phase:bool):
		if (phase):
			self.phase = b"\x01"
		else:
			self.phase = b"\x00"
		self.addr = addr
		self.vid = vid
		self.padding = bytes(37)#random.randbytes(37)
		
	def __init__(self):
		self.random()
	
	def raw(self):
		r = bytearray()
		r += self.addr
		r += self.vid
		r += self.padding
		assert(len(r) == 46, f"expected 46, got length {len(r)} value {r.hex()}")
		return r
	
	def __str__(self) -> string:
		s = ""
		for i, b in enumerate(self.addr):
			if i: 
				s += ":" 
			s += f"{b:02x}"
		s+= " "+self.vid.hex()[0:3]+" "
		if self.phase[0] & 0x01:	
			s += "1"
		else: 
			s += "0"
		return s
