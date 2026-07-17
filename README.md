# 100Mbps Ethernet Switch ASIC

Fully open source variable port cut-through unmanaged 100Mbps ethernet switch ASIC targeting the [Global Foundry 180nm MCU node (gf180mcuD)](https://gf180mcu-pdk.readthedocs.io/en/latest/). 

The first version of this design is a 3 port version, currently tapped out on the [Tiny Tapeout gf26b shuttle chip](https://tinytapeout.com/chips/ttgf26b/), part of the second [wafer.space](https://wafer.space/) run, and silicon bring-up is expected to start 2026-11-15. 

![feature](/docs/feature.png) 

The second version of this design is a 4 port version, part of the full [Expresso ASIC](https://github.com/Essenceia/Expresso_ASIC_Chip), an Ethernet focused fully open source chip, applying to be part of the sponsored open source project on the second [wafer.space](https://wafer.space/) run. 

![full chip](/docs/ws_run2_chip.png)

Features: 
- Full duplex Ethernet ports, 100Mbps over RMII
- Configurable port counts
- Unmanaged switch 
- Cut-though forwarding 

## Overview 

This ASIC will behave like any other unmanaged cut-though Ethernet switch, using it on a network should be as simple as connecting it and forgetting it. No additional setup is required. 

This unmanaged switch is equipped with a small internal mac address table to keep track of which devices
are connected downstream of each of its ports. During operations it will autonomously update this internal 
table based on the source mac addresses of incoming packets. When packets addressed to a known entry are received, they are routed only to the port associated with this entry. If a packet is targeting an unknown destination mac address or a broadcast address the packet is broadcasted on all ports apart 
from the port it is coming from. 

## Future Improvements 

List of other future improvements :
- 10Mbps support with dynamic switching between 100Mbps and 10Mbps
- Add perf counters and expose said counters over JTAG 
- Expand the number of routing entries:
	- Add more pure digital entires 
	- Move to using an analog CAM (content addressable memory) for the address resolution table

## Coffee-shop Chip family 

This ASIC is part of a larger family of open-source Ethernet connected IP featuring: 
- [`coffeepot` first generation switch (this project).](https://github.com/Essenceia/ethernet_switch_asic)
- [`teapot` Ethernet wrapper for building network connected accelerators.](https://github.com/Essenceia/Teapot)
- [`coldbrew` Ethernet connected beacon for broadcasting an ethernet frame with an uptime count until the heat death of the universe.](https://github.com/Essenceia/Until_Heat_Death_Do_Us_Part)

## Credits

Thanks to the Tiny Tapeout and wafer.space projects, its contributors, and all the community working on open source silicon tools for making this possible.

## License 

This hardware is distributed under the **strongly** reciprocal CERN Open Hardware Licence Version 2 unless
otherwise specified.

### Tiny Tapeout exception

Any submission of this design, or derivatives thereof, made through the Tiny Tapeout 
shuttle program is additionally licensed under the Apache License 2.0 and is exempt from the 
reciprocal requirements of CERN-OHL-S-2.0 solely for that purpose.


