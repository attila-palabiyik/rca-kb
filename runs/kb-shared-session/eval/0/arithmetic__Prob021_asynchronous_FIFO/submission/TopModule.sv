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
    parameter ADDR_WIDTH = (DEPTH > 1) ? $clog2(DEPTH) : 1;
    localparam [ADDR_WIDTH-1:0] LAST_ADDR = DEPTH - 1;

    reg [ADDR_WIDTH:0] waddr_bin, raddr_bin;
    reg [ADDR_WIDTH:0] wptr, rptr;
    (* ASYNC_REG = "TRUE" *) reg [ADDR_WIDTH:0] rptr_buff, rptr_syn;
    (* ASYNC_REG = "TRUE" *) reg [ADDR_WIDTH:0] wptr_buff, wptr_syn;

    wire wen = wrstn && winc && !wfull;
    wire ren = rrstn && rinc && !rempty;

    function automatic [ADDR_WIDTH:0] advance_pointer(input [ADDR_WIDTH:0] ptr);
        if (ptr[ADDR_WIDTH-1:0] == LAST_ADDR)
            advance_pointer = {~ptr[ADDR_WIDTH], {ADDR_WIDTH{1'b0}}};
        else
            advance_pointer = ptr + 1'b1;
    endfunction

    function automatic [ADDR_WIDTH:0] gray_pointer(input [ADDR_WIDTH:0] ptr);
        reg [ADDR_WIDTH-1:0] index;
        begin
            // Traverse the address codes in reverse on the second lap.
            // At either wrap, the lap bit is the only bit that changes.
            index = ptr[ADDR_WIDTH-1:0];
            if (ptr[ADDR_WIDTH])
                index = LAST_ADDR - index;
            gray_pointer = {ptr[ADDR_WIDTH], index ^ (index >> 1)};
        end
    endfunction

    wire [ADDR_WIDTH:0] waddr_next = advance_pointer(waddr_bin);
    wire [ADDR_WIDTH:0] raddr_next = advance_pointer(raddr_bin);

    assign wfull = (rptr_syn == gray_pointer({~waddr_bin[ADDR_WIDTH],
                                             waddr_bin[ADDR_WIDTH-1:0]}));
    assign rempty = (rptr == wptr_syn);

    always @(posedge wclk or negedge wrstn) begin
        if (!wrstn) begin
            waddr_bin <= 0;
            wptr <= 0;
            rptr_buff <= 0;
            rptr_syn <= 0;
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
            raddr_bin <= 0;
            rptr <= 0;
            wptr_buff <= 0;
            wptr_syn <= 0;
        end else begin
            if (ren) begin
                raddr_bin <= raddr_next;
                rptr <= gray_pointer(raddr_next);
            end
            wptr_buff <= wptr;
            wptr_syn <= wptr_buff;
        end
    end

    dual_port_RAM #(.DEPTH(DEPTH), .WIDTH(WIDTH)) u_ram (
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
					   parameter WIDTH = 8,
                       localparam ADDR_WIDTH = (DEPTH > 1) ? $clog2(DEPTH) : 1)(
	 input wclk
	,input wenc
	,input [ADDR_WIDTH-1:0] waddr  //Take log2 of depth to get address bit width.
	,input [WIDTH-1:0] wdata      	//Data write
	,input rclk
	,input renc
	,input [ADDR_WIDTH-1:0] raddr  //Take log2 of depth to get address bit width.
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
