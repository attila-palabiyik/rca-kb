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
localparam [DP_WD-1:0] LAST_ADDR = DP_WD'(DEPTH - 1);
 
reg  [DP_WD   :0]waddr;
wire             wenc;
wire             waddr_d_h;
wire [DP_WD -1:0]waddr_d_l;
wire             wwrap = (waddr[DP_WD-1:0] == LAST_ADDR);
assign wenc = rst_n & winc & !wfull;
assign waddr_d_h = waddr[DP_WD] ^ wwrap;
assign waddr_d_l = wwrap ? {DP_WD{1'b0}} : waddr[DP_WD-1:0] + 1'b1;
always @(posedge clk or negedge rst_n)begin
	if(~rst_n)    waddr <= 0;
	else if(wenc) waddr <= {waddr_d_h, waddr_d_l};
end
 
reg  [DP_WD   :0]raddr;
wire             renc;
wire             raddr_d_h;
wire [DP_WD -1:0]raddr_d_l;
wire             rwrap = (raddr[DP_WD-1:0] == LAST_ADDR);
assign renc = rst_n & rinc & !rempty;
assign raddr_d_h = raddr[DP_WD] ^ rwrap;
assign raddr_d_l = rwrap ? {DP_WD{1'b0}} : raddr[DP_WD-1:0] + 1'b1;
always @(posedge clk or negedge rst_n)begin
	if(~rst_n)    raddr <= 0;
	else if(renc) raddr <= {raddr_d_h, raddr_d_l};
end
 
assign rempty = (waddr == raddr);
assign wfull = (waddr[DP_WD] != raddr[DP_WD]) &&
               (waddr[DP_WD-1:0] == raddr[DP_WD-1:0]);
 
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
					   parameter WIDTH = 8,
					   localparam ADDR_WIDTH = (DEPTH > 1) ? $clog2(DEPTH) : 1)(
	 input wclk
	,input wenc
	,input [ADDR_WIDTH-1:0] waddr
	,input [WIDTH-1:0] wdata      	//Data write
	,input rclk
	,input renc
	,input [ADDR_WIDTH-1:0] raddr
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
