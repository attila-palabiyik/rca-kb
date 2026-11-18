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
 
localparam DP_WD = (DEPTH > 1) ? $clog2(DEPTH) : 1;
 
reg  [DP_WD   :0]waddr;
wire             wenc;
wire             waddr_d_h;
wire [DP_WD -1:0]waddr_d_l;
assign wenc = rst_n & winc & !wfull;
assign waddr_d_h = (waddr[DP_WD-1:0] == DEPTH-1) ? ~waddr[DP_WD] : waddr[DP_WD];
assign waddr_d_l = (waddr[DP_WD-1:0] == DEPTH-1) ? 0 : waddr[DP_WD-1:0] + 1;
always @(posedge clk or negedge rst_n)begin
	if(~rst_n)    waddr <= 0;
	else if(wenc) waddr <= {waddr_d_h, waddr_d_l};
end
 
reg  [DP_WD   :0]raddr;
wire             renc;
wire             raddr_d_h;
wire [DP_WD -1:0]raddr_d_l;
assign renc = rst_n & rinc & !rempty;
assign raddr_d_h = (raddr[DP_WD-1:0] == DEPTH-1) ? ~raddr[DP_WD] : raddr[DP_WD];
assign raddr_d_l = (raddr[DP_WD-1:0] == DEPTH-1) ? 0 : raddr[DP_WD-1:0] + 1;
always @(posedge clk or negedge rst_n)begin
	if(~rst_n)    raddr <= 0;
	else if(renc) raddr <= {raddr_d_h, raddr_d_l};
end
 
// Equal RAM addresses indicate full or empty depending on the wrap bits.
assign rempty = (waddr == raddr);
assign wfull = (waddr[DP_WD-1:0] == raddr[DP_WD-1:0]) &&
               (waddr[DP_WD] != raddr[DP_WD]);
 
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

/**********************************RAM************************************/
module dual_port_RAM #(parameter DEPTH = 16,
					   parameter WIDTH = 8)(
	 input wclk
	,input wenc
	,input [((DEPTH > 1) ? $clog2(DEPTH) : 1)-1:0] waddr
	,input [WIDTH-1:0] wdata      	//Data write
	,input rclk
	,input renc
	,input [((DEPTH > 1) ? $clog2(DEPTH) : 1)-1:0] raddr
	,output reg [WIDTH-1:0] rdata 		//Data output
);
 
reg [WIDTH-1:0] RAM_MEM [0:DEPTH-1];
 
always @(posedge wclk) begin
	if(wenc)
		RAM_MEM[waddr] <= wdata;
end 
 
always @(posedge rclk) begin
	if(renc)
		rdata <= RAM_MEM[raddr];
end 
 
endmodule  
