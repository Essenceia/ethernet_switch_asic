//-----------------------------------------------------------------------------
// Copyright (C) 2009 OutputLogic.com
// This source file may be used and distributed without restriction
// provided that this copyright statement is not removed from the file
// and that any derivative work contains the original copyright notice
// and the associated disclaimer.
// THIS SOURCE FILE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS
// OR IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED	
// WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
//-----------------------------------------------------------------------------
// CRC module for
//	 data[7:0]
//	 crc[31:0]=1+x^1+x^2+x^4+x^5+x^7+x^8+x^10+x^11+x^12+x^16+x^22+x^23+x^26+x^32;
//
module crc_8(
	input wire         clk,
	input wire         crc_rst_i,
	input wire         crc_en_i,
	input wire  [7:0]  data_i,
	output wire [31:0] crc_o
);
reg [31:0] lfsr_q;
reg [31:0] lfsr_c;

assign crc_o = lfsr_q;

always @(*) begin
	lfsr_c[0] = lfsr_q[24] ^ lfsr_q[30] ^ data_i[0] ^ data_i[6];
	lfsr_c[1] = lfsr_q[24] ^ lfsr_q[25] ^ lfsr_q[30] ^ lfsr_q[31] ^ data_i[0] ^ data_i[1] ^ data_i[6] ^ data_i[7];
	lfsr_c[2] = lfsr_q[24] ^ lfsr_q[25] ^ lfsr_q[26] ^ lfsr_q[30] ^ lfsr_q[31] ^ data_i[0] ^ data_i[1] ^ data_i[2] ^ data_i[6] ^ data_i[7];
	lfsr_c[3] = lfsr_q[25] ^ lfsr_q[26] ^ lfsr_q[27] ^ lfsr_q[31] ^ data_i[1] ^ data_i[2] ^ data_i[3] ^ data_i[7];
	lfsr_c[4] = lfsr_q[24] ^ lfsr_q[26] ^ lfsr_q[27] ^ lfsr_q[28] ^ lfsr_q[30] ^ data_i[0] ^ data_i[2] ^ data_i[3] ^ data_i[4] ^ data_i[6];
	lfsr_c[5] = lfsr_q[24] ^ lfsr_q[25] ^ lfsr_q[27] ^ lfsr_q[28] ^ lfsr_q[29] ^ lfsr_q[30] ^ lfsr_q[31] ^ data_i[0] ^ data_i[1] ^ data_i[3] ^ data_i[4] ^ data_i[5] ^ data_i[6] ^ data_i[7];
	lfsr_c[6] = lfsr_q[25] ^ lfsr_q[26] ^ lfsr_q[28] ^ lfsr_q[29] ^ lfsr_q[30] ^ lfsr_q[31] ^ data_i[1] ^ data_i[2] ^ data_i[4] ^ data_i[5] ^ data_i[6] ^ data_i[7];
	lfsr_c[7] = lfsr_q[24] ^ lfsr_q[26] ^ lfsr_q[27] ^ lfsr_q[29] ^ lfsr_q[31] ^ data_i[0] ^ data_i[2] ^ data_i[3] ^ data_i[5] ^ data_i[7];
	lfsr_c[8] = lfsr_q[0] ^ lfsr_q[24] ^ lfsr_q[25] ^ lfsr_q[27] ^ lfsr_q[28] ^ data_i[0] ^ data_i[1] ^ data_i[3] ^ data_i[4];
	lfsr_c[9] = lfsr_q[1] ^ lfsr_q[25] ^ lfsr_q[26] ^ lfsr_q[28] ^ lfsr_q[29] ^ data_i[1] ^ data_i[2] ^ data_i[4] ^ data_i[5];
	lfsr_c[10] = lfsr_q[2] ^ lfsr_q[24] ^ lfsr_q[26] ^ lfsr_q[27] ^ lfsr_q[29] ^ data_i[0] ^ data_i[2] ^ data_i[3] ^ data_i[5];
	lfsr_c[11] = lfsr_q[3] ^ lfsr_q[24] ^ lfsr_q[25] ^ lfsr_q[27] ^ lfsr_q[28] ^ data_i[0] ^ data_i[1] ^ data_i[3] ^ data_i[4];
	lfsr_c[12] = lfsr_q[4] ^ lfsr_q[24] ^ lfsr_q[25] ^ lfsr_q[26] ^ lfsr_q[28] ^ lfsr_q[29] ^ lfsr_q[30] ^ data_i[0] ^ data_i[1] ^ data_i[2] ^ data_i[4] ^ data_i[5] ^ data_i[6];
	lfsr_c[13] = lfsr_q[5] ^ lfsr_q[25] ^ lfsr_q[26] ^ lfsr_q[27] ^ lfsr_q[29] ^ lfsr_q[30] ^ lfsr_q[31] ^ data_i[1] ^ data_i[2] ^ data_i[3] ^ data_i[5] ^ data_i[6] ^ data_i[7];
	lfsr_c[14] = lfsr_q[6] ^ lfsr_q[26] ^ lfsr_q[27] ^ lfsr_q[28] ^ lfsr_q[30] ^ lfsr_q[31] ^ data_i[2] ^ data_i[3] ^ data_i[4] ^ data_i[6] ^ data_i[7];
	lfsr_c[15] = lfsr_q[7] ^ lfsr_q[27] ^ lfsr_q[28] ^ lfsr_q[29] ^ lfsr_q[31] ^ data_i[3] ^ data_i[4] ^ data_i[5] ^ data_i[7];
	lfsr_c[16] = lfsr_q[8] ^ lfsr_q[24] ^ lfsr_q[28] ^ lfsr_q[29] ^ data_i[0] ^ data_i[4] ^ data_i[5];
	lfsr_c[17] = lfsr_q[9] ^ lfsr_q[25] ^ lfsr_q[29] ^ lfsr_q[30] ^ data_i[1] ^ data_i[5] ^ data_i[6];
	lfsr_c[18] = lfsr_q[10] ^ lfsr_q[26] ^ lfsr_q[30] ^ lfsr_q[31] ^ data_i[2] ^ data_i[6] ^ data_i[7];
	lfsr_c[19] = lfsr_q[11] ^ lfsr_q[27] ^ lfsr_q[31] ^ data_i[3] ^ data_i[7];
	lfsr_c[20] = lfsr_q[12] ^ lfsr_q[28] ^ data_i[4];
	lfsr_c[21] = lfsr_q[13] ^ lfsr_q[29] ^ data_i[5];
	lfsr_c[22] = lfsr_q[14] ^ lfsr_q[24] ^ data_i[0];
	lfsr_c[23] = lfsr_q[15] ^ lfsr_q[24] ^ lfsr_q[25] ^ lfsr_q[30] ^ data_i[0] ^ data_i[1] ^ data_i[6];
	lfsr_c[24] = lfsr_q[16] ^ lfsr_q[25] ^ lfsr_q[26] ^ lfsr_q[31] ^ data_i[1] ^ data_i[2] ^ data_i[7];
	lfsr_c[25] = lfsr_q[17] ^ lfsr_q[26] ^ lfsr_q[27] ^ data_i[2] ^ data_i[3];
	lfsr_c[26] = lfsr_q[18] ^ lfsr_q[24] ^ lfsr_q[27] ^ lfsr_q[28] ^ lfsr_q[30] ^ data_i[0] ^ data_i[3] ^ data_i[4] ^ data_i[6];
	lfsr_c[27] = lfsr_q[19] ^ lfsr_q[25] ^ lfsr_q[28] ^ lfsr_q[29] ^ lfsr_q[31] ^ data_i[1] ^ data_i[4] ^ data_i[5] ^ data_i[7];
	lfsr_c[28] = lfsr_q[20] ^ lfsr_q[26] ^ lfsr_q[29] ^ lfsr_q[30] ^ data_i[2] ^ data_i[5] ^ data_i[6];
	lfsr_c[29] = lfsr_q[21] ^ lfsr_q[27] ^ lfsr_q[30] ^ lfsr_q[31] ^ data_i[3] ^ data_i[6] ^ data_i[7];
	lfsr_c[30] = lfsr_q[22] ^ lfsr_q[28] ^ lfsr_q[31] ^ data_i[4] ^ data_i[7];
	lfsr_c[31] = lfsr_q[23] ^ lfsr_q[29] ^ data_i[5];
end // always

always @(posedge clk)
	if(crc_rst_i) lfsr_q  <= {32{1'b1}};
	else lfsr_q  <= crc_en_i ? lfsr_c : lfsr_q;

endmodule // crc
