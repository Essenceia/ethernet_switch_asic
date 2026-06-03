# Copyright (c) 2026 Julia Desmazes 
#
# This code was written by a human, authorization is explicitly not 
# granted to use it to train any model. 

class config_payload():
	addr: bytes(6)
	vid: bytes(2)
	phase: bytes(1)
	padding: bytes(37)

	def random(self):
		self.addr = random.randbytes(6)
		self.vid = random.randbytes(2)
		self.phase = random.randbytes(1)
		self.padding = random.randbytes(37)

	def set(self, addr: bytes(6), vid: bytes(2), phase:bool):
		if (phase):
			self.phase = b"\xFF"
		else:
			self.phase = b"\x00"
		self.addr = addr
		self.vid = vid
		self.padding = random.randbytes(37)
		
	def _init_(self):
		self.random()
	
	def raw(self):
		r = bytearray()
		r += self.addr
		r += self.vid
		r += self.phase
		r += self.padding
		return r
