#include "packets.h"
#include <string.h> 
#include <arpa/inet.h>
#include <stdlib.h> 
#include <stdio.h>
#include "math_lib.hpp" 
#include "eth_intf.h"

void set_header(eth_header_t* header, 
	mac_addr_t dst, mac_addr_t src, uint16_t ethtype)
{
	memcpy(header->dst_mac, dst, MAC_W);
	memcpy(header->src_mac, src, MAC_W);
	header->ethtype = ethtype;
}

app_packet_t* create_app_packet(
	mac_addr_t dst_mac, mac_addr_t src_mac, 
	uint16_t a, uint16_t b)
{
	app_packet_t *pkt; 
	pkt = (app_packet_t*) malloc(sizeof(app_packet_t));
	memset(pkt, 0, APP_PACKET_LENGTH);// set padding to 0, cleaner to read pcaps, no functional value
	set_header(&pkt->header, dst_mac, src_mac, htons(APP_ETHTYPE));
	pkt->a = htons(a);
	pkt->b = htons(b); 
	return pkt; 
}

void print_raw_packet(uint8_t *pkt, size_t pkt_lenght){
	assert(pkt); 
	for(size_t i=0; i< pkt_lenght; i++){
		printf("%02x", pkt[i]);
	}
}

void print_header(eth_header_t h){
	printf("dst mac ");
	print_mac(h.dst_mac);
	printf("src mac ");
	print_mac(h.src_mac);
	printf("ethtype %04x\n", htons(h.ethtype));
}

void print_app_packet(app_packet_t *pkt, bool is_req){
	printf("\n%s app packet:\n", is_req? "request":"response");
	print_header(pkt->header);
	if (is_req){
		printf("a: ");
		print_bf16(pkt->a);
		printf("\nb: ");
		print_bf16(pkt->b);
	} else {
		printf("c: ");
		print_bf16(pkt->a);
	}
	printf("\nraw: ");
	print_raw_packet((uint8_t*)pkt, APP_PACKET_LENGTH);
	printf("\n\n");
}
