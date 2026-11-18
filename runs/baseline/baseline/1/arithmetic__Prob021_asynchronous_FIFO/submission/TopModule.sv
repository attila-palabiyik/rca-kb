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
    input      [WIDTH-1:0]  wdata,
    output reg              wfull,
    output reg              rempty,
    output wire [WIDTH-1:0] rdata
);

localparam ADDR_WIDTH = DEPTH > 1 ? $clog2(DEPTH) : 1;
localparam [ADDR_WIDTH-1:0] LAST_ADDR = ADDR_WIDTH'(DEPTH - 1);

reg [ADDR_WIDTH:0] waddr_bin, raddr_bin;
reg [ADDR_WIDTH:0] wptr, rptr;
(* ASYNC_REG = "TRUE" *) reg [ADDR_WIDTH:0] rptr_buff, rptr_syn;
(* ASYNC_REG = "TRUE" *) reg [ADDR_WIDTH:0] wptr_buff, wptr_syn;

wire wen = wrstn && winc && !wfull;
wire ren = rrstn && rinc && !rempty;

function automatic [ADDR_WIDTH:0] advance;
    input [ADDR_WIDTH:0] ptr;
    begin
        if (ptr[ADDR_WIDTH-1:0] == LAST_ADDR)
            advance = {~ptr[ADDR_WIDTH], {ADDR_WIDTH{1'b0}}};
        else
            advance = ptr + 1'b1;
    end
endfunction

// The second lap reverses the address sequence before Gray encoding.
// At each wrap the encoded address stays fixed and only the lap bit changes.
function automatic [ADDR_WIDTH:0] gray_pointer;
    input [ADDR_WIDTH:0] ptr;
    reg [ADDR_WIDTH-1:0] addr;
    begin
        addr = ptr[ADDR_WIDTH-1:0];
        if (ptr[ADDR_WIDTH])
            addr = LAST_ADDR - addr;
        gray_pointer = {ptr[ADDR_WIDTH], addr ^ (addr >> 1)};
    end
endfunction

wire [ADDR_WIDTH:0] waddr_next = wen ? advance(waddr_bin) : waddr_bin;
wire [ADDR_WIDTH:0] raddr_next = ren ? advance(raddr_bin) : raddr_bin;
wire [ADDR_WIDTH:0] wptr_next = gray_pointer(waddr_next);
wire [ADDR_WIDTH:0] rptr_next = gray_pointer(raddr_next);

// Full means the next write pointer and the read pointer address the same
// RAM entry with opposite lap bits.
wire [ADDR_WIDTH:0] full_match =
    gray_pointer({~waddr_next[ADDR_WIDTH], waddr_next[ADDR_WIDTH-1:0]});

always @(posedge wclk or negedge wrstn) begin
    if (!wrstn) begin
        waddr_bin <= '0;
        wptr      <= '0;
        wfull     <= 1'b0;
        rptr_buff <= '0;
        rptr_syn  <= '0;
    end else begin
        waddr_bin <= waddr_next;
        wptr      <= wptr_next;
        wfull     <= (full_match == rptr_syn);
        rptr_buff <= rptr;
        rptr_syn  <= rptr_buff;
    end
end

always @(posedge rclk or negedge rrstn) begin
    if (!rrstn) begin
        raddr_bin <= '0;
        rptr      <= '0;
        rempty    <= 1'b1;
        wptr_buff <= '0;
        wptr_syn  <= '0;
    end else begin
        raddr_bin <= raddr_next;
        rptr      <= rptr_next;
        rempty    <= (rptr_next == wptr_syn);
        wptr_buff <= wptr;
        wptr_syn  <= wptr_buff;
    end
end

dual_port_RAM #(.DEPTH(DEPTH), .WIDTH(WIDTH)) storage (
    .wclk  (wclk),
    .wenc  (wen),
    .waddr (waddr_bin[ADDR_WIDTH-1:0]),
    .wdata (wdata),
    .rclk  (rclk),
    .renc  (ren),
    .raddr (raddr_bin[ADDR_WIDTH-1:0]),
    .rdata (rdata)
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
