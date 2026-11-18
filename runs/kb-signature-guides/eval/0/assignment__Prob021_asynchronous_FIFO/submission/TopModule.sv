module TopModule #(
    parameter WIDTH = 8,
    parameter DEPTH = 16
)(
    input wire wclk,
    input wire rclk,
    input wire wrstn,
    input wire rrstn,
    input wire winc,
    input wire rinc,
    input wire [WIDTH-1:0] wdata,
    output wire wfull,
    output wire rempty,
    output wire [WIDTH-1:0] rdata
);

parameter ADDR_WIDTH = $clog2(DEPTH);

// Use a power-of-two address ring so the Gray pointers change one bit
// per transfer, including at wraparound. Limit occupancy to DEPTH.
localparam RAM_ADDR_WIDTH = (ADDR_WIDTH < 1) ? 1 : ADDR_WIDTH;
localparam RAM_DEPTH = 2 ** RAM_ADDR_WIDTH;

reg [RAM_ADDR_WIDTH:0] waddr_bin;
reg [RAM_ADDR_WIDTH:0] raddr_bin;
reg [RAM_ADDR_WIDTH:0] wptr;
reg [RAM_ADDR_WIDTH:0] rptr;

wire wen = wrstn && winc && !wfull;
wire ren = rrstn && rinc && !rempty;
wire [RAM_ADDR_WIDTH:0] waddr_next = waddr_bin + 1'b1;
wire [RAM_ADDR_WIDTH:0] raddr_next = raddr_bin + 1'b1;

// The RAM uses the current address and both pointer forms advance together.
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

assign rempty = (rptr == wptr_syn);

generate
    if (DEPTH == RAM_DEPTH) begin : full_ring
        // A distance of one address ring flips the two upper Gray bits.
        localparam [RAM_ADDR_WIDTH:0] FULL_MASK = 2'b11 << (RAM_ADDR_WIDTH-1);
        assign wfull = (wptr == (rptr_syn ^ FULL_MASK));
    end else begin : limited_capacity
        wire [RAM_ADDR_WIDTH:0] raddr_syn_bin;
        wire [RAM_ADDR_WIDTH:0] used_words = waddr_bin - raddr_syn_bin;
        localparam [RAM_ADDR_WIDTH:0] CAPACITY = DEPTH;

        // Each binary bit is the parity of the Gray bits at and above it.
        for (genvar bit_index = 0; bit_index <= RAM_ADDR_WIDTH; bit_index = bit_index + 1) begin : decode_read_pointer
            assign raddr_syn_bin[bit_index] = ^rptr_syn[RAM_ADDR_WIDTH:bit_index];
        end

        assign wfull = (used_words == CAPACITY);
    end
endgenerate

dual_port_RAM #(
    .DEPTH(RAM_DEPTH),
    .WIDTH(WIDTH)
) dual_port_RAM (
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
