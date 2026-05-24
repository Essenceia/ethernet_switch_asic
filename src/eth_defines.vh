/*
Copyright (c) 2026 Julia Desmazes 

This code was written by a human, authorization is explicitly not 
granted to use it to train any model. 
*/

/* verilator lint_off VARHIDDEN */

/* Shared project ethernet values definitions */

localparam PHY_W = 2; 
// MAC
localparam MAC_W = 48;
localparam [MAC_W-1:0] DEFAULT_MAC = 48'hAAAAAAAAAA;

localparam ADDR_CNT = (MAC_W / (8/PHY_W)) - 1;
localparam ADDR_CNT_W = $clog2(ADDR_CNT); 

localparam SFD_W = 8; 
localparam [SFD_W-1:0] SFD = 8'b10101011; 

localparam FRAME_TYPE_W = 16;
localparam FRAME_TYPE_CNT = (FRAME_TYPE_W / (8/PHY_W)) - 1;
localparam FRAME_TYPE_CNT_W = $clog2(FRAME_TYPE_CNT);

localparam [FRAME_TYPE_W-1:0] TYPE_VLAN = 16'h8100;
localparam VID_W = 12;

// support jumbo frames upto 9000 bytes long
localparam MAX_FRAME_BYTE_SIZE = 9000;
localparam MAX_FRAME_SIZE = 9000 * (8/PHY_W);
localparam FRAME_SIZE_W = $clog2(MAX_FRAME_SIZE);

// FCS 
localparam FCS_W = 32; 

localparam DELAY_DEPTH = FCS_W / (8/PHY_W);

/* verilator lint_on VARHIDDEN */

