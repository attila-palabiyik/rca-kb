module TopModule #(
    parameter WIDTH = 8,
    parameter DEPTH = 16
)(
    input                  wclk,
    input                  rclk,
    input                  wrstn,
    input                  rrstn,
    input                  winc,
    input                  rinc,
    input      [WIDTH-1:0] wdata,
    output wire            wfull,
    output wire            rempty,
    output wire [WIDTH-1:0] rdata
);

parameter ADDR_WIDTH = $clog2(DEPTH);
localparam RAM_ADDR_WIDTH = (ADDR_WIDTH > 0) ? ADDR_WIDTH : 1;
localparam [RAM_ADDR_WIDTH-1:0] LAST_ADDR = RAM_ADDR_WIDTH'(DEPTH - 1);

reg [RAM_ADDR_WIDTH:0] waddr_bin, raddr_bin;
reg [RAM_ADDR_WIDTH:0] wptr, rptr;
(* ASYNC_REG = "TRUE" *) reg [RAM_ADDR_WIDTH:0] rptr_buff, rptr_syn;
(* ASYNC_REG = "TRUE" *) reg [RAM_ADDR_WIDTH:0] wptr_buff, wptr_syn;

wire wen = wrstn && winc && !wfull;
wire ren = rrstn && rinc && !rempty;
wire [RAM_ADDR_WIDTH-1:0] waddr = waddr_bin[RAM_ADDR_WIDTH-1:0];
wire [RAM_ADDR_WIDTH-1:0] raddr = raddr_bin[RAM_ADDR_WIDTH-1:0];

function automatic [RAM_ADDR_WIDTH:0] advance;
    input [RAM_ADDR_WIDTH:0] ptr;
    begin
        if (ptr[RAM_ADDR_WIDTH-1:0] == LAST_ADDR)
            advance = {~ptr[RAM_ADDR_WIDTH], {RAM_ADDR_WIDTH{1'b0}}};
        else
            advance = ptr + 1'b1;
    end
endfunction

// The second pass visits the address Gray codes in reverse order.
// At either wrap the address code stays the same and only the wrap bit flips.
function automatic [RAM_ADDR_WIDTH:0] to_gray;
    input [RAM_ADDR_WIDTH:0] ptr;
    reg [RAM_ADDR_WIDTH-1:0] addr;
    begin
        addr = ptr[RAM_ADDR_WIDTH-1:0];
        if (ptr[RAM_ADDR_WIDTH])
            addr = LAST_ADDR - addr;
        to_gray = {ptr[RAM_ADDR_WIDTH], addr ^ (addr >> 1)};
    end
endfunction

wire [RAM_ADDR_WIDTH:0] waddr_next = advance(waddr_bin);
wire [RAM_ADDR_WIDTH:0] raddr_next = advance(raddr_bin);

always @(posedge wclk or negedge wrstn) begin
    if (!wrstn) begin
        waddr_bin <= '0;
        wptr <= '0;
    end else if (wen) begin
        waddr_bin <= waddr_next;
        wptr <= to_gray(waddr_next);
    end
end

always @(posedge rclk or negedge rrstn) begin
    if (!rrstn) begin
        raddr_bin <= '0;
        rptr <= '0;
    end else if (ren) begin
        raddr_bin <= raddr_next;
        rptr <= to_gray(raddr_next);
    end
end

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

// Full means the read pointer is at the write address in the opposite pass.
assign wfull = (rptr_syn == to_gray({~waddr_bin[RAM_ADDR_WIDTH], waddr}));
assign rempty = (rptr == wptr_syn);

dual_port_RAM #(.DEPTH(DEPTH), .WIDTH(WIDTH)) dual_port_RAM (
    .wclk  (wclk),
    .wenc  (wen),
    .waddr (waddr),
    .wdata (wdata),
    .rclk  (rclk),
    .renc  (ren),
    .raddr (raddr),
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
