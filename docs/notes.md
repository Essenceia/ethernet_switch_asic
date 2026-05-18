# 10BASE-T 

Can be optionally half-duplex, but if we only do full duplex I don't need to do CDSM/CA, and I hate collision detection!
So we are doing only full-duplex DTE. 

Functions required (14.2.1) 
- Transmit 
- Receive
- Loopback 
- Jabber (?) 
	- Provides the ability to prevent abnormally long reception of Manchester-encoded data on the DO circuit from indefinitely disrupting transmission on the network. While such a condition is present, transfer of Manchester-encoded data by the Transmit and Loopback functions is disabled.
- Link Integrety Test
	- detect the link is not connected: send/receive link test pulses (LTPs)  

## Encoding: Manchester

0 -> high to low transition 10 
1 -> low to high 01 

Transitions occure at the 50ns mark, a signal is send ever 100ns (10Mbps)

## Packet 

### Idle 

After a packet has been transmitted a start of idle `TP_IDL` signal is sent. 
This is a positive signal of lasting at least 250ns. 

### Preamble

10BASE-T also includes a 7 bit preamble: 7'b10101010 

### Start of frame delimiter

After the preamble, but before the MAC header there is also a 8 bit start 
of frame delimiter 8'haa

### Inter Packet Gap 

After each transmission the MAC enforces an IPG of at leat 96 bit times (or 9.6 us)
during wich the line is left idle (0V differential voltage). 

# Sublayers


- The Physical Signaling (PLS) sublayer,
- The Medium Attachment Unit (MAU) sublayer, which itself consists of
	- the Physical Medium Attachment (PMA) sublayer, and
	- the Medium Dependent Interface (MDI) sublayer.
- The Attachment Unit Interface (AUI), a cable which connects the PLS and MAU sublayers together.

## MAU Medium Attachement Unit 

MDI + PMA 

Things I don't need: 
- monitor mode


## AUI 

Defined in clause 7, though it is not required that these be physically defined, rather there are just logical terms. 

# Ressources

- 802.3 IEEE spec

[https://ctrlsrc.io/posts/2023/niccle-ethernet-10base-t-overview/](https://ctrlsrc.io/posts/2023/niccle-ethernet-10base-t-overview/)
[https://www.iol.unh.edu/sites/default/files/knowledgebase/ethernet/10basetmau.pdf](https://www.iol.unh.edu/sites/default/files/knowledgebase/ethernet/10basetmau.pdf)

