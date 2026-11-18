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
localparam RAM_ADDR_WIDTH = DEPTH > 1 ? $clog2(DEPTH) : 1;
localparam [ADDR_WIDTH:0] FIFO_DEPTH = DEPTH;

wire wen = wrstn && winc && !wfull;
wire ren = rrstn && rinc && !rempty;

reg [ADDR_WIDTH:0] waddr_bin, raddr_bin;
reg [ADDR_WIDTH:0] wptr, rptr;
wire [ADDR_WIDTH:0] waddr_next = waddr_bin + wen;
wire [ADDR_WIDTH:0] raddr_next = raddr_bin + ren;

always @(posedge wclk or negedge wrstn) begin
    if (!wrstn) begin
        waddr_bin <= '0;
        wptr <= '0;
    end else begin
        waddr_bin <= waddr_next;
        wptr <= waddr_next ^ (waddr_next >> 1);
    end
end

always @(posedge rclk or negedge rrstn) begin
    if (!rrstn) begin
        raddr_bin <= '0;
        rptr <= '0;
    end else begin
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

assign rempty = (rptr == wptr_syn);

wire [RAM_ADDR_WIDTH-1:0] waddr, raddr;
generate
    if (DEPTH == (2 ** ADDR_WIDTH)) begin : power_of_two
        localparam [ADDR_WIDTH:0] FULL_MASK = FIFO_DEPTH ^ (FIFO_DEPTH >> 1);
        assign wfull = (wptr == (rptr_syn ^ FULL_MASK));
        assign waddr = DEPTH == 1 ? '0 : waddr_bin[RAM_ADDR_WIDTH-1:0];
        assign raddr = DEPTH == 1 ? '0 : raddr_bin[RAM_ADDR_WIDTH-1:0];
    end else begin : separate_ram_addresses
        // Keep the CDC counters on the full Gray cycle and wrap RAM addresses at DEPTH.
        localparam [RAM_ADDR_WIDTH-1:0] LAST_ADDR = DEPTH - 1;
        reg [RAM_ADDR_WIDTH-1:0] write_address, read_address;
        wire [ADDR_WIDTH:0] synced_read_count;
        wire [ADDR_WIDTH:0] used_words = waddr_bin - synced_read_count;

        for (genvar bit_index = 0; bit_index <= ADDR_WIDTH; bit_index = bit_index + 1) begin : decode_gray
            assign synced_read_count[bit_index] = ^rptr_syn[ADDR_WIDTH:bit_index];
        end

        assign wfull = (used_words == FIFO_DEPTH);
        assign waddr = write_address;
        assign raddr = read_address;

        always @(posedge wclk or negedge wrstn) begin
            if (!wrstn)
                write_address <= '0;
            else if (wen)
                write_address <= (write_address == LAST_ADDR) ? '0 : write_address + 1'b1;
        end

        always @(posedge rclk or negedge rrstn) begin
            if (!rrstn)
                read_address <= '0;
            else if (ren)
                read_address <= (read_address == LAST_ADDR) ? '0 : read_address + 1'b1;
        end
    end
endgenerate

dual_port_RAM #(
    .DEPTH(DEPTH),
    .WIDTH(WIDTH)
) dual_port_RAM (
    .wclk (wclk),
    .wenc (wen),
    .waddr(waddr),
    .wdata(wdata),
    .rclk (rclk),
    .renc (ren),
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
