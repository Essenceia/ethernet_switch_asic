# Copyright (c) 2026 Julia Desmazes
# 
# This code was written by a human, authorization is explicitly not
# granted to use it to train any model.

import random
import cocotb

# safe margin of timeout after which entries have expired
ENTRY_EXPIERY_TIMEOUT = 4000 
ENTRY_EXPIERY_TIMEOUT_SHORT = 2000 

ENTRY_NUM = 4 

TTNN_THRESHOLD = 3

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

def _lookup_seen_per_mac(src_mac: bytes(6)) -> tuple[bytes(6), int]:
	for mac, port in _seen_mac:
		if mac == src_mac:
			return mac, port
	assert 0, f"didn't find {src_mac} in table {_seen_mac}"

def is_seen_src_mac(src_mac: bytes(6)) -> bool:
	for mac, _ in _seen_mac:
		if mac == src_mac:
			return True
	return False

def seen_src_mac_cnt(dut, gates: str = "yes" ) -> int:
	if gates == "":
		alive_cnt = dut.m_dut.m_coffeepot.m_switch.m_lookup.m_dispatcher.m_table.cocotb_entry_alloc_cnt.value 
		return alive_cnt.to_unsigned() 
	else:
		return len(_seen_mac)

def add_seen_src_mac(src_mac: bytes(6), src_port: int):
	for i, (seen_mac, seen_port) in enumerate(_seen_mac):
		if src_mac == seen_mac:
			_seen_mac.pop(i)
	_seen_mac.insert(0, tuple((src_mac, src_port)))
	if len(_seen_mac) >= ENTRY_NUM:
		_seen_mac.pop()
		assert len(_seen_mac) <= ENTRY_NUM

def random_seen_src_mac(dut, gates: str = "yes") -> tuple[bytes(6), int]:
	assert len(_seen_mac) > 0, f"Empty seen list"
	assert len(_seen_mac) <= ENTRY_NUM, f"Unexpected seen list length, got {len(_seen_mac)}"
	while True:
		mac, port = _seen_mac[random.randrange(0,len(_seen_mac))]
		if gates == "":
			if _check_alive_margin(dut, mac):
				break
			elif _check_survivor(dut) == False:
				assert 0, "Unexpected: everybody is dead" 
		else: 
			break
	return mac, port

def _check_survivor(dut) -> bool:
	all_dead = dut.m_dut.m_coffeepot.m_switch.m_lookup.m_dispatcher.m_table.cocotb_nobody_is_alive.value 
	return all_dead != 1

def _check_alive_margin(dut, mac : bytes(6)) -> bool:
	for i in range(0, ENTRY_NUM):
		entry_mac =  dut.m_dut.m_coffeepot.m_switch.m_lookup.m_dispatcher.m_table.cocotb_entry_mac[i].value 
		entry_mac_bytes = entry_mac.to_bytes( byteorder = 'big')
		if entry_mac_bytes == mac: 
			entry_ttnn =  dut.m_dut.m_coffeepot.m_switch.m_lookup.m_dispatcher.m_table.cocotb_entry_ttnn[i].value 
			if (entry_ttnn.to_unsigned() >= TTNN_THRESHOLD):
				return True
			else:
				return False
	assert 0, f"Failed to find entry for mac {mac}"
			
