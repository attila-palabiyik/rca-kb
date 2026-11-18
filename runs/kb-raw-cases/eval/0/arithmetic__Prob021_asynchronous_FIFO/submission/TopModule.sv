module TopModule #(
    parameter WIDTH = 8,
    parameter DEPTH = 16,
    parameter ADDR_WIDTH = $clog2(DEPTH)
)(
    input wire wclk,
    input wire rclk,
    input wire wrstn,
    input wire rrstn,
    input wire winc,
    input wire rinc,
    input wire [WIDTH-1:0] wdata,
    output reg wfull,
    output reg rempty,
    output wire [WIDTH-1:0] rdata
);

localparam RAM_ADDR_WIDTH = (DEPTH > 1) ? $clog2(DEPTH) : 1;
localparam [ADDR_WIDTH:0] CAPACITY = DEPTH;
localparam [RAM_ADDR_WIDTH-1:0] LAST_ADDR = DEPTH - 1;

reg [ADDR_WIDTH:0] waddr_bin, raddr_bin;
reg [ADDR_WIDTH:0] wptr, rptr;
(* ASYNC_REG = "TRUE" *) reg [ADDR_WIDTH:0] rptr_buff, rptr_syn;
(* ASYNC_REG = "TRUE" *) reg [ADDR_WIDTH:0] wptr_buff, wptr_syn;

wire wen = wrstn && winc && !wfull;
wire ren = rrstn && rinc && !rempty;
wire [ADDR_WIDTH:0] wbin_next = waddr_bin + wen;
wire [ADDR_WIDTH:0] rbin_next = raddr_bin + ren;
wire [ADDR_WIDTH:0] wgray_next = wbin_next ^ (wbin_next >> 1);
wire [ADDR_WIDTH:0] rgray_next = rbin_next ^ (rbin_next >> 1);

// The FIFO is full when the next write position is DEPTH entries
// ahead of the synchronized read position.
wire [ADDR_WIDTH:0] full_rbin = wbin_next - CAPACITY;
wire [ADDR_WIDTH:0] full_rgray = full_rbin ^ (full_rbin >> 1);

always @(posedge wclk or negedge wrstn) begin
    if (!wrstn) begin
        waddr_bin <= '0;
        wptr <= '0;
        rptr_buff <= '0;
        rptr_syn <= '0;
        wfull <= 1'b0;
    end else begin
        waddr_bin <= wbin_next;
        wptr <= wgray_next;
        rptr_buff <= rptr;
        rptr_syn <= rptr_buff;
        wfull <= (full_rgray == rptr_syn);
    end
end

always @(posedge rclk or negedge rrstn) begin
    if (!rrstn) begin
        raddr_bin <= '0;
        rptr <= '0;
        wptr_buff <= '0;
        wptr_syn <= '0;
        rempty <= 1'b1;
    end else begin
        raddr_bin <= rbin_next;
        rptr <= rgray_next;
        wptr_buff <= wptr;
        wptr_syn <= wptr_buff;
        rempty <= (rgray_next == wptr_syn);
    end
end

wire [RAM_ADDR_WIDTH-1:0] waddr, raddr;
generate
    if ((DEPTH & (DEPTH - 1)) == 0) begin : power_of_two_depth
        if (DEPTH == 1) begin : single_entry
            assign waddr = '0;
            assign raddr = '0;
        end else begin : multiple_entries
            assign waddr = waddr_bin[RAM_ADDR_WIDTH-1:0];
            assign raddr = raddr_bin[RAM_ADDR_WIDTH-1:0];
        end
    end else begin : arbitrary_depth
        // RAM addresses wrap at DEPTH. The CDC counters wrap at a power
        // of two so their Gray codes change one bit even at wraparound.
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

dual_port_RAM #(.DEPTH(DEPTH), .WIDTH(WIDTH)) dual_port_RAM (
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
