module TopModule#(
	parameter	WIDTH = 8,
	parameter 	DEPTH = 16
)(
	input 					clk		, 
	input 					rst_n	,
	input 					winc	,
	input 			 		rinc	,
	input 		[WIDTH-1:0]	wdata	,
 
	output 				    wfull	,
	output 				    rempty	,
	output wire [WIDTH-1:0]	rdata
);
 
// With DEPTH=1, the supplied RAM declares its address ports as [-1:0].
localparam DP_WD = (DEPTH == 1) ? 2 : $clog2(DEPTH);
localparam [DP_WD-1:0] LAST_ADDR = DP_WD'(DEPTH - 1);
 
reg  [DP_WD   :0]waddr;
wire             wenc;
wire             waddr_d_h;
wire [DP_WD -1:0]waddr_d_l;
assign wenc = rst_n & winc & !wfull;
assign waddr_d_h = (waddr[DP_WD-1:0] == LAST_ADDR) ? ~waddr[DP_WD] : waddr[DP_WD];
assign waddr_d_l = (waddr[DP_WD-1:0] == LAST_ADDR) ? 0 : waddr[DP_WD-1:0] + 1;

always @(posedge clk or negedge rst_n) begin
	if (~rst_n)
		waddr <= 0;
	else if (wenc)
		waddr <= {waddr_d_h, waddr_d_l};
end 

reg  [DP_WD   :0]raddr;
wire             renc;
wire             raddr_d_h;
wire [DP_WD -1:0]raddr_d_l;
assign renc = rst_n & rinc & !rempty;
assign raddr_d_h = (raddr[DP_WD-1:0] == LAST_ADDR) ? ~raddr[DP_WD] : raddr[DP_WD];
assign raddr_d_l = (raddr[DP_WD-1:0] == LAST_ADDR) ? 0 : raddr[DP_WD-1:0] + 1;

always @(posedge clk or negedge rst_n)begin
	if(~rst_n)    raddr <= 0;
	else if(renc) raddr <= {raddr_d_h, raddr_d_l};
end
 
wire same_addr = (waddr[DP_WD-1:0] == raddr[DP_WD-1:0]);
assign rempty = same_addr && (waddr[DP_WD] == raddr[DP_WD]);
assign wfull = same_addr && (waddr[DP_WD] != raddr[DP_WD]);
 
dual_port_RAM #(.DEPTH(DEPTH), .WIDTH(WIDTH))
u_ram (
	.wclk	(clk),
	.wenc	(wenc),
	.waddr	(waddr[DP_WD-1:0]),
	.wdata	(wdata),
	.rclk	(clk),
	.renc	(renc),
	.raddr	(raddr[DP_WD-1:0]),
	.rdata	(rdata)
);
 
endmodule
