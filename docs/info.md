<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->
3 port cut-through 100Mbps ethernet switch ASIC targetting the Global Foundary 180nm MCU node. 

## Overview

This is an simple 3-port unmanaged 100Mbps Ethernet Switch, just plug
in the ethernet and let it route packets. Packets will be routed
based on there mac addresses and the switch will keep track of 
the addresses of the devices connected to each port by tracking the 
`source address` field in the ethernet frame header of incomming ethernet packets.

## Setup

Connect the 3 RMII PHY interfaces to RMII compliant PHY chips such as the LAN8720A, all 
the PHYs and the ASIC should be using the same external 50MHz reference clock.

A link to a test PCB design will be provided at a later date. 

## External hardware

Ethernet 100BASE-T Pmod connector: 
- 3x100Mbps RMII compliant PHYs (LAN8720A)
- 50MHz oscillator

