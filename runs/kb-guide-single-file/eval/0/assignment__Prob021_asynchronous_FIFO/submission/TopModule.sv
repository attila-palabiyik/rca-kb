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

parameter ADDR_WIDTH = (DEPTH > 1) ? $clog2(DEPTH) : 1;
localparam [ADDR_WIDTH:0] FIFO_DEPTH = (ADDR_WIDTH+1)'(DEPTH);

wire wen = wrstn && winc && !wfull;
wire ren = rrstn && rinc && !rempty;

/**********************local pointers*************************/
reg 	[ADDR_WIDTH:0]	waddr_bin;
reg 	[ADDR_WIDTH:0]	raddr_bin;
reg 	[ADDR_WIDTH:0]	wptr;
reg 	[ADDR_WIDTH:0]	rptr;
wire	[ADDR_WIDTH:0]	waddr_next = waddr_bin + {{ADDR_WIDTH{1'b0}}, wen};
wire	[ADDR_WIDTH:0]	raddr_next = raddr_bin + {{ADDR_WIDTH{1'b0}}, ren};

// Advance the binary and registered Gray pointers on the same edge.
always @(posedge wclk or negedge wrstn) begin
	if(!wrstn) begin
		waddr_bin <= 'd0;
		wptr <= 'd0;
	end else begin
		waddr_bin <= waddr_next;
		wptr <= waddr_next ^ (waddr_next >> 1);
	end
end
always @(posedge rclk or negedge rrstn) begin
	if(!rrstn) begin
		raddr_bin <= 'd0;
		rptr <= 'd0;
	end else begin
		raddr_bin <= raddr_next;
		rptr <= raddr_next ^ (raddr_next >> 1);
	end
end
/**********************syn addr gray*************************/
(* ASYNC_REG = "TRUE" *) reg [ADDR_WIDTH:0] wptr_buff, wptr_syn;
(* ASYNC_REG = "TRUE" *) reg [ADDR_WIDTH:0] rptr_buff, rptr_syn;
always @(posedge wclk or negedge wrstn) begin 
	if(~wrstn) begin
		rptr_buff <= 'd0;
		rptr_syn <= 'd0;
	end 
	else begin
		rptr_buff <= rptr;
		rptr_syn <= rptr_buff;
	end
end
always @(posedge rclk or negedge rrstn) begin 
	if(~rrstn) begin
		wptr_buff <= 'd0;
		wptr_syn <= 'd0;
	end 
	else begin
		wptr_buff <= wptr;
		wptr_syn <= wptr_buff;
	end
end
/**********************full empty gen*************************/
// Full when the synchronized read pointer is DEPTH operations behind.
wire [ADDR_WIDTH:0] full_read_bin = waddr_bin - FIFO_DEPTH;
wire [ADDR_WIDTH:0] full_read_gray = full_read_bin ^ (full_read_bin >> 1);
assign wfull = (rptr_syn == full_read_gray);
assign rempty = (rptr == wptr_syn);

/**********************RAM*************************/
wire [ADDR_WIDTH-1:0]	waddr;
wire [ADDR_WIDTH-1:0]	raddr;

generate
	if (DEPTH == 1) begin : single_entry
		assign waddr = '0;
		assign raddr = '0;
	end else if ((DEPTH & (DEPTH - 1)) == 0) begin : power_of_two_depth
		assign waddr = waddr_bin[ADDR_WIDTH-1:0];
		assign raddr = raddr_bin[ADDR_WIDTH-1:0];
	end else begin : other_depth
		// RAM addresses wrap at DEPTH, while the Gray counters keep
		// their power-of-two period so each advance changes one bit.
		localparam [ADDR_WIDTH-1:0] LAST_ADDR = ADDR_WIDTH'(DEPTH - 1);
		reg [ADDR_WIDTH-1:0] write_addr, read_addr;

		always @(posedge wclk or negedge wrstn) begin
			if (!wrstn)
				write_addr <= '0;
			else if (wen)
				write_addr <= (write_addr == LAST_ADDR) ? '0 : write_addr + 1'b1;
		end

		always @(posedge rclk or negedge rrstn) begin
			if (!rrstn)
				read_addr <= '0;
			else if (ren)
				read_addr <= (read_addr == LAST_ADDR) ? '0 : read_addr + 1'b1;
		end

		assign waddr = write_addr;
		assign raddr = read_addr;
	end
endgenerate

dual_port_RAM #(.DEPTH(DEPTH),
				.WIDTH(WIDTH),
				.ADDR_WIDTH(ADDR_WIDTH)
)dual_port_RAM(
	.wclk (wclk),  
	.wenc (wen),  
	.waddr(waddr),
	.wdata(wdata),       	//Data write
	.rclk (rclk), 
	.renc (ren), 
	.raddr(raddr),
	.rdata(rdata)  		//Data output
);

endmodule

module dual_port_RAM #(parameter DEPTH = 16,
					   parameter WIDTH = 8,
					   parameter ADDR_WIDTH = (DEPTH > 1) ? $clog2(DEPTH) : 1)(
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
