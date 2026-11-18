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
    output reg wfull,
    output reg rempty,
    output wire [WIDTH-1:0] rdata
);
    parameter ADDR_WIDTH = (DEPTH > 1) ? $clog2(DEPTH) : 1;

    // A power-of-two address ring keeps the Gray transition at wrap to one bit.
    // The full flag limits the usable capacity to DEPTH.
    localparam RAM_DEPTH = 2 ** ADDR_WIDTH;
    localparam [ADDR_WIDTH:0] CAPACITY = DEPTH;

    reg [ADDR_WIDTH:0] waddr_bin, raddr_bin;
    reg [ADDR_WIDTH:0] wptr, rptr;
    (* ASYNC_REG = "TRUE" *) reg [ADDR_WIDTH:0] rptr_buff, rptr_syn;
    (* ASYNC_REG = "TRUE" *) reg [ADDR_WIDTH:0] wptr_buff, wptr_syn;

    wire wen = wrstn && winc && !wfull;
    wire ren = rrstn && rinc && !rempty;
    wire [ADDR_WIDTH:0] waddr_next = waddr_bin + wen;
    wire [ADDR_WIDTH:0] raddr_next = raddr_bin + ren;
    wire [ADDR_WIDTH:0] wptr_next = waddr_next ^ (waddr_next >> 1);
    wire [ADDR_WIDTH:0] rptr_next = raddr_next ^ (raddr_next >> 1);

    function automatic [ADDR_WIDTH:0] gray_to_binary(input [ADDR_WIDTH:0] gray);
        integer bit_index;
        begin
            gray_to_binary[ADDR_WIDTH] = gray[ADDR_WIDTH];
            for (bit_index = ADDR_WIDTH - 1; bit_index >= 0; bit_index = bit_index - 1)
                gray_to_binary[bit_index] = gray_to_binary[bit_index + 1] ^ gray[bit_index];
        end
    endfunction

    wire [ADDR_WIDTH:0] used_next = waddr_next - gray_to_binary(rptr_syn);

    always @(posedge wclk or negedge wrstn) begin
        if (!wrstn) begin
            waddr_bin <= 0;
            wptr <= 0;
            rptr_buff <= 0;
            rptr_syn <= 0;
            wfull <= 1'b0;
        end else begin
            waddr_bin <= waddr_next;
            wptr <= wptr_next;
            rptr_buff <= rptr;
            rptr_syn <= rptr_buff;
            wfull <= (used_next >= CAPACITY);
        end
    end

    always @(posedge rclk or negedge rrstn) begin
        if (!rrstn) begin
            raddr_bin <= 0;
            rptr <= 0;
            wptr_buff <= 0;
            wptr_syn <= 0;
            rempty <= 1'b1;
        end else begin
            raddr_bin <= raddr_next;
            rptr <= rptr_next;
            wptr_buff <= wptr;
            wptr_syn <= wptr_buff;
            rempty <= (rptr_next == wptr_syn);
        end
    end

    dual_port_RAM #(.DEPTH(RAM_DEPTH), .WIDTH(WIDTH)) u_ram (
        .wclk(wclk),
        .wenc(wen),
        .waddr(waddr_bin[ADDR_WIDTH-1:0]),
        .wdata(wdata),
        .rclk(rclk),
        .renc(ren),
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
