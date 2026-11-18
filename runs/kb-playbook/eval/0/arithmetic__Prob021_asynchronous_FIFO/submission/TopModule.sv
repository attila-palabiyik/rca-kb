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
    input       [WIDTH-1:0] wdata,
    output wire             wfull,
    output wire             rempty,
    output wire [WIDTH-1:0] rdata
);

parameter ADDR_WIDTH = (DEPTH > 1) ? $clog2(DEPTH) : 1;
localparam [ADDR_WIDTH-1:0] LAST_ADDR = ADDR_WIDTH'(DEPTH - 1);
localparam [ADDR_WIDTH:0] WRAP_BIT = {1'b1, {ADDR_WIDTH{1'b0}}};

reg [ADDR_WIDTH:0] waddr_bin;
reg [ADDR_WIDTH:0] raddr_bin;
reg [ADDR_WIDTH:0] wptr;
reg [ADDR_WIDTH:0] rptr;

wire wen = wrstn && winc && !wfull;
wire ren = rrstn && rinc && !rempty;

function automatic [ADDR_WIDTH:0] advance_pointer;
    input [ADDR_WIDTH:0] pointer;
    begin
        if (pointer[ADDR_WIDTH-1:0] == LAST_ADDR)
            advance_pointer = {~pointer[ADDR_WIDTH], {ADDR_WIDTH{1'b0}}};
        else
            advance_pointer = pointer + 1'b1;
    end
endfunction

function automatic [ADDR_WIDTH:0] encode_pointer;
    input [ADDR_WIDTH:0] pointer;
    reg [ADDR_WIDTH-1:0] address;
    begin
        // Traverse the address Gray codes in reverse on the second lap.
        // At either wrap, only the lap bit changes, even for other depths.
        address = pointer[ADDR_WIDTH-1:0];
        if (pointer[ADDR_WIDTH])
            address = LAST_ADDR - address;
        encode_pointer = {pointer[ADDR_WIDTH], address ^ (address >> 1)};
    end
endfunction

wire [ADDR_WIDTH:0] waddr_next = advance_pointer(waddr_bin);
wire [ADDR_WIDTH:0] raddr_next = advance_pointer(raddr_bin);

always @(posedge wclk or negedge wrstn) begin
    if (!wrstn) begin
        waddr_bin <= '0;
        wptr <= '0;
    end else if (wen) begin
        waddr_bin <= waddr_next;
        wptr <= encode_pointer(waddr_next);
    end
end

always @(posedge rclk or negedge rrstn) begin
    if (!rrstn) begin
        raddr_bin <= '0;
        rptr <= '0;
    end else if (ren) begin
        raddr_bin <= raddr_next;
        rptr <= encode_pointer(raddr_next);
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

assign wfull = (encode_pointer(waddr_bin ^ WRAP_BIT) == rptr_syn);
assign rempty = (rptr == wptr_syn);

dual_port_RAM #(.DEPTH(DEPTH), .WIDTH(WIDTH)) dual_port_RAM (
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
