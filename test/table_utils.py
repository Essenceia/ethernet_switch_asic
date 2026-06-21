# Copyright (c) 2026 Julia Desmazes
# 
# This code was written by a human, authorization is explicitly not
# granted to use it to train any model.

import random

# safe margin of timeout after which entries have expired
ENTRY_EXPIERY_TIMEOUT = 4000 
ENTRY_EXPIERY_TIMEOUT_SHORT = 2000 

ENTRY_NUM = 4 

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

_seen_mac = []
def clear_seen_src_mac() -> list:
	_seen_mac = []

def _lookup_seen_per_mac(src_mac: bytes(6)) -> tuple(bytes(6), int):
	for mac, port in _seen_mac:
		if mac == src_mac:
			return mac, port
	assert 0, f"didn't find {src_mac} in table {_seen_mac}"

def is_seen_src_mac(src_mac: bytes(6)) -> bool:
	for mac, _ in _seen_mac:
		if mac == src_mac:
			return True
	return False

def seen_src_mac_cnt() -> int:
	return _seen_mac.len()

def add_seen_src_mac(src_mac: bytes(6), src_port: int):
	if src_mac in _seen_mac:
		_seen_mac.pop(_seen_mac.index(src_mac))
	_seen_mac.insert(0, tuple(src_mac, src_port))
	if _seen_mac.len() >= ENTRY_NUM:
		_seen_mac.pop()
		assert(_seen_mac.len() <= ENTRY_NUM)

def random_seen_src_mac() -> tuple(bytes(6), int):
	assert _seen_mac.len() > 0, f"Empty seen list"
	assert _seen_mac.len() <= ENTRY_NUM, f"Unexpected seen list length, got {_seen_mac.len()}"
	return _seen_mac[random.randrange(0,_seen_mac.len()]
