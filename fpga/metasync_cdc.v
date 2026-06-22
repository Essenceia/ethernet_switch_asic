`default_nettype none

module metasync_cdc #(
    parameter DATA_W = 3,
    parameter ADDR_W = 3   
)(
    input  wire                wclk,
    input  wire [DATA_W-1:0]   wdata,

    input  wire                rclk,
    input  wire                rrst_n,
    output reg  [DATA_W-1:0]   rdata
);
localparam N = 1 << ADDR_W;

reg [DATA_W-1:0] mem [0:N-1];
reg [ADDR_W-1:0] waddr;
reg [ADDR_W-1:0] raddr;

always @(posedge wclk or negedge rrst_n) begin
	if (~rrst_n) begin
        waddr <= N/2;
    end else begin
        mem[waddr] <= wdata;
        waddr      <= waddr + 1'b1;
    end
end

always @(posedge rclk or negedge rrst_n) begin
	if (~rrst_n) begin
        raddr <= 0; 
    end else begin
        rdata <= mem[raddr];
        raddr <= raddr + 1'b1;
    end
end

endmodule
