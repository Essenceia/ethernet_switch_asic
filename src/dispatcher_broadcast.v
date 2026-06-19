/*
Copyright (c) 2026 Julia Desmazes 

This code was written by a human, authorization is explicitly not 
granted to use it to train any model. 
*/

`default_nettype none

module dispatcher_broadcast #(
	localparam PORT_CNT = 3,
	localparam DISP_SEL_W = PORT_CNT*(PORT_CNT-1)
)(
	input wire [PORT_CNT-1:0] new_req_i, 
	input wire [PORT_CNT-1:0] free_i,

	output wire [PORT_CNT-1:0] new_dispatch_o,
	output wire [DISP_SEL_W-1:0] dir_o	
);
// select high priority req
wire [PORT_CNT-1:0] prio_req; 
assign prio_req[0] = new_req_i[0];
assign prio_req[1] = new_req_i[1] & ~new_req_i[0];
assign prio_req[2] = new_req_i[2] & ~|new_req_i[1:0];

reg [PORT_CNT-1:0] new_disp_lite;
reg [DISP_SEL_W-1:0] dir;

localparam PS = PORT_CNT - 1; // port selection on dispatcher

always @(*) begin
	case(prio_req)
		3'b001: begin
			new_disp_lite   = 3'b110;
			dir[PS-1-:PS]   = 2'b00; // tx0
			dir[2*PS-1-:PS] = 2'b01; // tx1
			dir[3*PS-1-:PS] = 2'b01; // tx2
	end
		3'b010: begin
			new_disp_lite   = 3'b101;
			dir[PS-1-:PS]   = 2'b01; // tx0
			dir[2*PS-1-:PS] = 2'b00; // tx1
			dir[3*PS-1-:PS] = 2'b10; // tx2
		end	
		3'b100: begin
			new_disp_lite   = 3'b011;
			dir[PS-1-:PS]   = 2'b10; // tx0
			dir[2*PS-1-:PS] = 2'b10; // tx1
			dir[3*PS-1-:PS] = 2'b00; // tx2
		end	
		default: begin // 3'b000
			new_disp_lite = {PORT_CNT{1'b0}};
			dir           = {DISP_SEL_W{1'b0}};
		end	
	endcase
end

assign new_dispatch_o = free_i & new_disp_lite;
assign dir_o = dir; 

endmodule	
