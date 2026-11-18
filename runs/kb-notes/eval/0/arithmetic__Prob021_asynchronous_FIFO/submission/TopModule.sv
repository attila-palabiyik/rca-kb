module TopModule #(
    parameter WIDTH = 8,
    parameter DEPTH = 16
)(
    input wclk,
    input rclk,
    input wrstn,
    input rrstn,
    input winc,
    input rinc,
    input [WIDTH-1:0] wdata,
    output wire wfull,
    output wire rempty,
    output wire [WIDTH-1:0] rdata
);

parameter ADDR_WIDTH = $clog2(DEPTH);
localparam RAM_ADDR_WIDTH = ADDR_WIDTH > 0 ? ADDR_WIDTH : 1;
localparam [RAM_ADDR_WIDTH-1:0] LAST_ADDR = RAM_ADDR_WIDTH'(DEPTH - 1);

reg [RAM_ADDR_WIDTH:0] waddr_bin, raddr_bin;
reg [RAM_ADDR_WIDTH:0] wptr, rptr;
(* ASYNC_REG = "TRUE" *) reg [RAM_ADDR_WIDTH:0] rptr_buff, rptr_syn;
(* ASYNC_REG = "TRUE" *) reg [RAM_ADDR_WIDTH:0] wptr_buff, wptr_syn;

wire wen = wrstn && winc && !wfull;
wire ren = rrstn && rinc && !rempty;

function automatic [RAM_ADDR_WIDTH:0] advance_pointer(
    input [RAM_ADDR_WIDTH:0] pointer
);
    if (pointer[RAM_ADDR_WIDTH-1:0] == LAST_ADDR)
        advance_pointer = {~pointer[RAM_ADDR_WIDTH], {RAM_ADDR_WIDTH{1'b0}}};
    else
        advance_pointer = pointer + 1'b1;
endfunction

function automatic [RAM_ADDR_WIDTH:0] gray_pointer(
    input [RAM_ADDR_WIDTH:0] pointer
);
    reg [RAM_ADDR_WIDTH-1:0] index;
    begin
        // Traverse the lower Gray codes in reverse on alternate laps.
        // At either wrap, the lower code holds and only the lap bit flips.
        index = pointer[RAM_ADDR_WIDTH-1:0];
        if (pointer[RAM_ADDR_WIDTH])
            index = LAST_ADDR - index;
        gray_pointer = {pointer[RAM_ADDR_WIDTH], index ^ (index >> 1)};
    end
endfunction

wire [RAM_ADDR_WIDTH:0] waddr_next = advance_pointer(waddr_bin);
wire [RAM_ADDR_WIDTH:0] raddr_next = advance_pointer(raddr_bin);

always @(posedge wclk or negedge wrstn) begin
    if (!wrstn) begin
        waddr_bin <= '0;
        wptr <= '0;
        rptr_buff <= '0;
        rptr_syn <= '0;
    end else begin
        if (wen) begin
            waddr_bin <= waddr_next;
            wptr <= gray_pointer(waddr_next);
        end
        rptr_buff <= rptr;
        rptr_syn <= rptr_buff;
    end
end

always @(posedge rclk or negedge rrstn) begin
    if (!rrstn) begin
        raddr_bin <= '0;
        rptr <= '0;
        wptr_buff <= '0;
        wptr_syn <= '0;
    end else begin
        if (ren) begin
            raddr_bin <= raddr_next;
            rptr <= gray_pointer(raddr_next);
        end
        wptr_buff <= wptr;
        wptr_syn <= wptr_buff;
    end
end

// Full means the read pointer is at the write address on the opposite lap.
wire [RAM_ADDR_WIDTH:0] full_pointer =
    gray_pointer({~waddr_bin[RAM_ADDR_WIDTH], waddr_bin[RAM_ADDR_WIDTH-1:0]});
assign wfull = (rptr_syn == full_pointer);
assign rempty = (rptr == wptr_syn);

dual_port_RAM #(.DEPTH(DEPTH), .WIDTH(WIDTH)) dual_port_RAM (
    .wclk(wclk),
    .wenc(wen),
    .waddr(waddr_bin[RAM_ADDR_WIDTH-1:0]),
    .wdata(wdata),
    .rclk(rclk),
    .renc(ren),
    .raddr(raddr_bin[RAM_ADDR_WIDTH-1:0]),
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
