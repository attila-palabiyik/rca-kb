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
localparam RAM_ADDR_WIDTH = (DEPTH > 1) ? $clog2(DEPTH) : 1;
localparam [ADDR_WIDTH:0] FIFO_DEPTH = DEPTH;

wire wen = wrstn && winc && !wfull;
wire ren = rrstn && rinc && !rempty;

reg [ADDR_WIDTH:0] waddr_bin;
reg [ADDR_WIDTH:0] raddr_bin;
reg [ADDR_WIDTH:0] wptr;
reg [ADDR_WIDTH:0] rptr;
wire [ADDR_WIDTH:0] waddr_next = waddr_bin + 1'b1;
wire [ADDR_WIDTH:0] raddr_next = raddr_bin + 1'b1;

// Advance each binary pointer and its Gray encoding on the RAM access edge.
always @(posedge wclk or negedge wrstn) begin
	if (!wrstn) begin
		waddr_bin <= '0;
		wptr <= '0;
	end else if (wen) begin
		waddr_bin <= waddr_next;
		wptr <= waddr_next ^ (waddr_next >> 1);
	end
end

always @(posedge rclk or negedge rrstn) begin
	if (!rrstn) begin
		raddr_bin <= '0;
		rptr <= '0;
	end else if (ren) begin
		raddr_bin <= raddr_next;
		rptr <= raddr_next ^ (raddr_next >> 1);
	end
end

(* ASYNC_REG = "TRUE" *) reg [ADDR_WIDTH:0] rptr_buff, rptr_syn;
(* ASYNC_REG = "TRUE" *) reg [ADDR_WIDTH:0] wptr_buff, wptr_syn;

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

// Full when the synchronized reader is DEPTH positions behind the writer.
wire [ADDR_WIDTH:0] full_raddr_bin = waddr_bin - FIFO_DEPTH;
wire [ADDR_WIDTH:0] full_rptr = full_raddr_bin ^ (full_raddr_bin >> 1);
assign wfull = (rptr_syn == full_rptr);
assign rempty = (rptr == wptr_syn);

wire [RAM_ADDR_WIDTH-1:0] waddr;
wire [RAM_ADDR_WIDTH-1:0] raddr;

generate
	if (DEPTH == 1) begin : single_entry
		assign waddr = '0;
		assign raddr = '0;
	end else if ((DEPTH & (DEPTH - 1)) == 0) begin : power_of_two
		assign waddr = waddr_bin[RAM_ADDR_WIDTH-1:0];
		assign raddr = raddr_bin[RAM_ADDR_WIDTH-1:0];
	end else begin : wrap_at_depth
		// RAM addresses wrap at DEPTH while the CDC pointers keep their
		// power-of-two Gray cycle.
		localparam [RAM_ADDR_WIDTH-1:0] LAST_ADDR = DEPTH - 1;
		reg [RAM_ADDR_WIDTH-1:0] write_addr, read_addr;

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

dual_port_RAM #(.DEPTH(DEPTH), .WIDTH(WIDTH)) dual_port_RAM(
	.wclk(wclk),
	.wenc(wen),
	.waddr(waddr),
	.wdata(wdata),
	.rclk(rclk),
	.renc(ren),
	.raddr(raddr),
	.rdata(rdata)
);

endmodule

module dual_port_RAM #(parameter DEPTH = 16,
					   parameter WIDTH = 8)(
	 input wclk
	,input wenc
	,input [((DEPTH > 1) ? $clog2(DEPTH) : 1)-1:0] waddr  //Take log2 of depth to get address bit width.
	,input [WIDTH-1:0] wdata      	//Data write
	,input rclk
	,input renc
	,input [((DEPTH > 1) ? $clog2(DEPTH) : 1)-1:0] raddr  //Take log2 of depth to get address bit width.
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
