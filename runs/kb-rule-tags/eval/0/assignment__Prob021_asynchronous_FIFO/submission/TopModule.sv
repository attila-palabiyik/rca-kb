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

localparam POINTER_ADDR_WIDTH = (ADDR_WIDTH > 0) ? ADDR_WIDTH : 1;
localparam RAM_DEPTH = (DEPTH > 1) ? DEPTH : 2;
localparam [POINTER_ADDR_WIDTH-1:0] LAST_ADDR = DEPTH - 1;
localparam [POINTER_ADDR_WIDTH:0] WRAP_MASK =
    {1'b1, LAST_ADDR ^ (LAST_ADDR >> 1)};

reg [POINTER_ADDR_WIDTH:0] waddr_bin, raddr_bin;
reg [POINTER_ADDR_WIDTH:0] wptr, rptr;

(* ASYNC_REG = "TRUE" *) reg [POINTER_ADDR_WIDTH:0] rptr_buff, rptr_syn;
(* ASYNC_REG = "TRUE" *) reg [POINTER_ADDR_WIDTH:0] wptr_buff, wptr_syn;

wire wen = wrstn && winc && !wfull;
wire ren = rrstn && rinc && !rempty;
wire [POINTER_ADDR_WIDTH-1:0] waddr = waddr_bin[POINTER_ADDR_WIDTH-1:0];
wire [POINTER_ADDR_WIDTH-1:0] raddr = raddr_bin[POINTER_ADDR_WIDTH-1:0];

function [POINTER_ADDR_WIDTH:0] advance_pointer;
    input [POINTER_ADDR_WIDTH:0] pointer;
    begin
        if (pointer[POINTER_ADDR_WIDTH-1:0] == LAST_ADDR)
            advance_pointer = {~pointer[POINTER_ADDR_WIDTH], {POINTER_ADDR_WIDTH{1'b0}}};
        else
            advance_pointer = pointer + 1'b1;
    end
endfunction

function [POINTER_ADDR_WIDTH:0] encode_pointer;
    input [POINTER_ADDR_WIDTH:0] pointer;
    reg [POINTER_ADDR_WIDTH-1:0] address;
    begin
        address = pointer[POINTER_ADDR_WIDTH-1:0];
        // Offset the second pass so a wrap changes only the phase bit
        // for any depth.
        encode_pointer = {1'b0, address ^ (address >> 1)};
        if (pointer[POINTER_ADDR_WIDTH])
            encode_pointer = encode_pointer ^ WRAP_MASK;
    end
endfunction

wire [POINTER_ADDR_WIDTH:0] waddr_next = advance_pointer(waddr_bin);
wire [POINTER_ADDR_WIDTH:0] raddr_next = advance_pointer(raddr_bin);

always @(posedge wclk or negedge wrstn) begin
    if (!wrstn) begin
        waddr_bin <= '0;
        wptr <= '0;
        rptr_buff <= '0;
        rptr_syn <= '0;
    end else begin
        if (wen) begin
            waddr_bin <= waddr_next;
            wptr <= encode_pointer(waddr_next);
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
            rptr <= encode_pointer(raddr_next);
        end
        wptr_buff <= wptr;
        wptr_syn <= wptr_buff;
    end
end

assign wfull = (wptr == (rptr_syn ^ WRAP_MASK));
assign rempty = (rptr == wptr_syn);

// A depth-one FIFO uses address zero through the RAM's one-bit ports.
dual_port_RAM #(.DEPTH(RAM_DEPTH), .WIDTH(WIDTH)) dual_port_RAM (
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
