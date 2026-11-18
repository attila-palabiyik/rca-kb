module TopModule#(
	parameter	WIDTH = 8,
	parameter 	DEPTH = 16
)(
	input 					wclk	, 
	input 					rclk	,   
	input 					wrstn	,
	input					rrstn	,
	input 					winc	,
	input 			 		rinc	,
	input 		[WIDTH-1:0]	wdata	,

	output wire				wfull	,
	output wire				rempty	,
	output wire [WIDTH-1:0]	rdata
);

parameter ADDR_WIDTH = $clog2(DEPTH);

// A power-of-two address ring keeps the Gray pointers single-bit at wrap.
// For other depths, the full check still limits occupancy to DEPTH words.
localparam RAM_ADDR_WIDTH = (ADDR_WIDTH < 1) ? 1 : ADDR_WIDTH;
localparam RAM_DEPTH = 2 ** RAM_ADDR_WIDTH;
localparam [RAM_ADDR_WIDTH:0] FIFO_CAPACITY = DEPTH;

wire wen = wrstn && winc && !wfull;
wire ren = rrstn && rinc && !rempty;

reg [RAM_ADDR_WIDTH:0] waddr_bin, raddr_bin;
reg [RAM_ADDR_WIDTH:0] wptr, rptr;
wire [RAM_ADDR_WIDTH:0] waddr_next = waddr_bin + wen;
wire [RAM_ADDR_WIDTH:0] raddr_next = raddr_bin + ren;

always @(posedge wclk or negedge wrstn) begin
	if (!wrstn) begin
		waddr_bin <= '0;
		wptr <= '0;
	end else begin
		waddr_bin <= waddr_next;
		wptr <= waddr_next ^ (waddr_next >> 1);
	end
end

always @(posedge rclk or negedge rrstn) begin
	if (!rrstn) begin
		raddr_bin <= '0;
		rptr <= '0;
	end else begin
		raddr_bin <= raddr_next;
		rptr <= raddr_next ^ (raddr_next >> 1);
	end
end

(* ASYNC_REG = "TRUE" *) reg [RAM_ADDR_WIDTH:0] rptr_buff, rptr_syn;
(* ASYNC_REG = "TRUE" *) reg [RAM_ADDR_WIDTH:0] wptr_buff, wptr_syn;

always @(posedge wclk or negedge wrstn) begin
	if (!wrstn) begin
		rptr_buff <= '0;
		rptr_syn <= '0;
	end else begin
		rptr_buff <= rptr;
		rptr_syn <= rptr_buff;
	end
end

always @(posedge rclk or negedge rrstn) begin
	if (!rrstn) begin
		wptr_buff <= '0;
		wptr_syn <= '0;
	end else begin
		wptr_buff <= wptr;
		wptr_syn <= wptr_buff;
	end
end

// Full when the synchronized read pointer is DEPTH positions behind the write pointer.
wire [RAM_ADDR_WIDTH:0] full_read_bin = waddr_bin - FIFO_CAPACITY;
assign wfull = (rptr_syn == (full_read_bin ^ (full_read_bin >> 1)));
assign rempty = (rptr == wptr_syn);

dual_port_RAM #(
	.DEPTH(RAM_DEPTH),
	.WIDTH(WIDTH)
) dual_port_RAM (
	.wclk (wclk),
	.wenc (wen),
	.waddr(waddr_bin[RAM_ADDR_WIDTH-1:0]),
	.wdata(wdata),
	.rclk (rclk),
	.renc (ren),
	.raddr(raddr_bin[RAM_ADDR_WIDTH-1:0]),
	.rdata(rdata)
);

endmodule

module dual_port_RAM #(parameter DEPTH = 16,
					   parameter WIDTH = 8)(
	 input wclk
	,input wenc
	,input [$clog2(DEPTH)-1:0] waddr  //Take log2 of depth to get address bit width.
	,input [WIDTH-1:0] wdata      	//Data write
	,input rclk
	,input renc
	,input [$clog2(DEPTH)-1:0] raddr  //Take log2 of depth to get address bit width.
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
