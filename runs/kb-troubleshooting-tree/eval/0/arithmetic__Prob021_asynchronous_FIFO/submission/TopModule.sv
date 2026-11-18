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

localparam ADDR_WIDTH = (DEPTH > 1) ? $clog2(DEPTH) : 1;
localparam PTR_WIDTH = ADDR_WIDTH + 1;
// A power-of-two address ring keeps the Gray transitions single-bit at wrap.
localparam RAM_DEPTH = 2**ADDR_WIDTH;
localparam [PTR_WIDTH-1:0] CAPACITY = PTR_WIDTH'(DEPTH);

reg [PTR_WIDTH-1:0] waddr_bin, raddr_bin;
reg [PTR_WIDTH-1:0] wptr, rptr;
(* ASYNC_REG = "TRUE" *) reg [PTR_WIDTH-1:0] rptr_buff, rptr_syn;
(* ASYNC_REG = "TRUE" *) reg [PTR_WIDTH-1:0] wptr_buff, wptr_syn;

wire wen = wrstn && winc && !wfull;
wire ren = rrstn && rinc && !rempty;
wire [PTR_WIDTH-1:0] waddr_next = waddr_bin + 1'b1;
wire [PTR_WIDTH-1:0] raddr_next = raddr_bin + 1'b1;

function automatic [PTR_WIDTH-1:0] gray_to_bin(input [PTR_WIDTH-1:0] gray);
    integer bit_index;
    begin
        gray_to_bin[PTR_WIDTH-1] = gray[PTR_WIDTH-1];
        for (bit_index = PTR_WIDTH-2; bit_index >= 0; bit_index = bit_index - 1)
            gray_to_bin[bit_index] = gray_to_bin[bit_index+1] ^ gray[bit_index];
    end
endfunction

always @(posedge wclk or negedge wrstn) begin
    if (!wrstn) begin
        waddr_bin <= 0;
        wptr <= 0;
        rptr_buff <= 0;
        rptr_syn <= 0;
    end else begin
        rptr_buff <= rptr;
        rptr_syn <= rptr_buff;
        if (wen) begin
            waddr_bin <= waddr_next;
            wptr <= waddr_next ^ (waddr_next >> 1);
        end
    end
end

always @(posedge rclk or negedge rrstn) begin
    if (!rrstn) begin
        raddr_bin <= 0;
        rptr <= 0;
        wptr_buff <= 0;
        wptr_syn <= 0;
    end else begin
        wptr_buff <= wptr;
        wptr_syn <= wptr_buff;
        if (ren) begin
            raddr_bin <= raddr_next;
            rptr <= raddr_next ^ (raddr_next >> 1);
        end
    end
end

// Limit the number of outstanding writes to the requested FIFO depth.
wire [PTR_WIDTH-1:0] used = waddr_bin - gray_to_bin(rptr_syn);
assign wfull = (used == CAPACITY);
assign rempty = (rptr == wptr_syn);

dual_port_RAM #(
    .DEPTH(RAM_DEPTH),
    .WIDTH(WIDTH)
) storage (
    .wclk (wclk),
    .wenc (wen),
    .waddr(waddr_bin[ADDR_WIDTH-1:0]),
    .wdata(wdata),
    .rclk (rclk),
    .renc (ren),
    .raddr(raddr_bin[ADDR_WIDTH-1:0]),
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
