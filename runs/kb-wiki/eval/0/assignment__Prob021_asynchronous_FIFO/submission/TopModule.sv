module TopModule #(
    parameter WIDTH = 8,
    parameter DEPTH = 16
)(
    input                   wclk,
    input                   rclk,
    input                   wrstn,
    input                   rrstn,
    input                   winc,
    input                   rinc,
    input  [WIDTH-1:0]      wdata,
    output wire             wfull,
    output wire             rempty,
    output wire [WIDTH-1:0] rdata
);

parameter ADDR_WIDTH = $clog2(DEPTH);
localparam RAM_ADDR_WIDTH = DEPTH > 1 ? $clog2(DEPTH) : 1;

// Use the middle 2*DEPTH counts of the binary range. The first and
// last counts are complements, so their Gray codes differ by one bit.
localparam [ADDR_WIDTH:0] HALF_RANGE = {1'b1, {ADDR_WIDTH{1'b0}}};
localparam [ADDR_WIDTH:0] DEPTH_COUNT = (ADDR_WIDTH+1)'(DEPTH);
localparam [ADDR_WIDTH:0] FIRST_COUNT = HALF_RANGE - DEPTH_COUNT;
localparam [ADDR_WIDTH:0] LAST_COUNT = HALF_RANGE + DEPTH_COUNT - 1'b1;
localparam [ADDR_WIDTH:0] RESET_GRAY = FIRST_COUNT ^ (FIRST_COUNT >> 1);

reg [ADDR_WIDTH:0] waddr_bin;
reg [ADDR_WIDTH:0] raddr_bin;
reg [ADDR_WIDTH:0] wptr;
reg [ADDR_WIDTH:0] rptr;
(* ASYNC_REG = "TRUE" *) reg [ADDR_WIDTH:0] wptr_buff, wptr_syn;
(* ASYNC_REG = "TRUE" *) reg [ADDR_WIDTH:0] rptr_buff, rptr_syn;

wire wen = wrstn && winc && !wfull;
wire ren = rrstn && rinc && !rempty;
wire [ADDR_WIDTH:0] waddr_next = waddr_bin == LAST_COUNT
                               ? FIRST_COUNT : waddr_bin + 1'b1;
wire [ADDR_WIDTH:0] raddr_next = raddr_bin == LAST_COUNT
                               ? FIRST_COUNT : raddr_bin + 1'b1;

always @(posedge wclk or negedge wrstn) begin
    if (!wrstn) begin
        waddr_bin <= FIRST_COUNT;
        wptr <= RESET_GRAY;
    end else if (wen) begin
        waddr_bin <= waddr_next;
        wptr <= waddr_next ^ (waddr_next >> 1);
    end
end

always @(posedge rclk or negedge rrstn) begin
    if (!rrstn) begin
        raddr_bin <= FIRST_COUNT;
        rptr <= RESET_GRAY;
    end else if (ren) begin
        raddr_bin <= raddr_next;
        rptr <= raddr_next ^ (raddr_next >> 1);
    end
end

always @(posedge wclk or negedge wrstn) begin
    if (!wrstn) begin
        rptr_buff <= RESET_GRAY;
        rptr_syn <= RESET_GRAY;
    end else begin
        rptr_buff <= rptr;
        rptr_syn <= rptr_buff;
    end
end

always @(posedge rclk or negedge rrstn) begin
    if (!rrstn) begin
        wptr_buff <= RESET_GRAY;
        wptr_syn <= RESET_GRAY;
    end else begin
        wptr_buff <= wptr;
        wptr_syn <= wptr_buff;
    end
end

// A full FIFO has equal RAM addresses in opposite halves of the cycle.
wire [ADDR_WIDTH:0] full_count = waddr_bin[ADDR_WIDTH]
                               ? waddr_bin - DEPTH_COUNT : waddr_bin + DEPTH_COUNT;
assign wfull = rptr_syn == (full_count ^ (full_count >> 1));
assign rempty = rptr == wptr_syn;

wire [RAM_ADDR_WIDTH-1:0] waddr = RAM_ADDR_WIDTH'(waddr_bin -
    (waddr_bin[ADDR_WIDTH] ? HALF_RANGE : FIRST_COUNT));
wire [RAM_ADDR_WIDTH-1:0] raddr = RAM_ADDR_WIDTH'(raddr_bin -
    (raddr_bin[ADDR_WIDTH] ? HALF_RANGE : FIRST_COUNT));

dual_port_RAM #(
    .DEPTH(DEPTH),
    .WIDTH(WIDTH)
) dual_port_RAM (
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
	,input [(DEPTH > 1 ? $clog2(DEPTH) : 1)-1:0] waddr  //Take log2 of depth to get address bit width.
	,input [WIDTH-1:0] wdata      	//Data write
	,input rclk
	,input renc
	,input [(DEPTH > 1 ? $clog2(DEPTH) : 1)-1:0] raddr  //Take log2 of depth to get address bit width.
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
