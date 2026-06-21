# Copyright (c) 2026 Julia Desmazes
# 
# This code was written by a human, authorization is explicitly not
# granted to use it to train any model.

import random

# safe margin of timeout after which entries have expired
ENTRY_EXPIERY_TIMEOUT = 4000 
ENTRY_EXPIERY_TIMEOUT_SHORT = 2000 

# generate random broadcast mac address for broadcast testing
def random_broadcast_mac() -> bytes(6):
	mac = bytearray()
	mac += random.randbytes(6)
	mac[0] = mac[0] | 0x01
	return mac	
	
def random_unicast_mac() -> bytes(6):
	mac = bytearray()
	mac += random.randbytes(6)
	mac[0] = mac[0] & 0xFE
	return mac	

