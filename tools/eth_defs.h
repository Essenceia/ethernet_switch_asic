#ifndef ETH_DEFS_H
#define ETH_DEFS_H

/* shared ethernet definitions and values */

#include <linux/if_ether.h>
#define ETH_P_802_EX2	0x88B6 // second experimental ethtype missing from linux headers

#define APP_ETHTYPE  ETH_P_802_EX1
#define CONF_ETHTYPE ETH_P_802_EX2

#define _MIN_ETH_FRAME_LENGTH 60
#define MAC_W 6 

#include <stdint.h>
typedef uint8_t mac_addr_t[MAC_W];

#define DEFAULT_ASIC_MAC {0x00, 0x90, 0xCF, 0x00, 0xBE, 0xEF}

// max ethernet frame length assuming no jumbo frame
#define ETH_FRAME_MAX_W 1514

#endif // ETH_DEFS_H
