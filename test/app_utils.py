# Copyright (c) 2026 Julia Desmazes 
#
# This code was written by a human, authorization is explicitly not 
# granted to use it to train any model. 

import cocotb 
import random

# generate random request payload for better test coverage
def random_request_payload() -> bytes(46):
	a = bytearray(0)
	b = bytearray(0)
	if random.randint(0,100) < 10:
		a.append(random.randint(0,255))
	else:
		a.append(0)
	if random.randint(0,100) < 10:
		b.append(random.randint(0,255))
	else: 
		b.append(0)
	a.append(random.randint(0,255))
	b.append(random.randint(0,255))
	req = bytearray(0)
	req += a
	req += b
	req += bytes(46-len(req))
	assert(len(a) == 2)
	assert(len(b) == 2)
	assert(len(req) == 46)
	return req

def layer3_app(payload:bytes(46)) -> bytes(46):
	a : int = int.from_bytes(payload[0:2], byteorder='big',signed=False)
	b : int = int.from_bytes(payload[2:4], byteorder='big',signed=False)
	res = a * b
	if (res > 2 ** 16):
		res = (2 ** 16) - 1
	resp = bytearray(0)
	resp.append( (res & 0xff00) >> 8)
	resp.append(res & 0xff)
	for _ in range(0, 46-2):
		resp.append(0)
	cocotb.log.debug(f"layer3 app {hex(a)}*{hex(b)}={hex(res)}\nreq {payload.hex()}\nres {resp.hex()}")
	return resp
	
