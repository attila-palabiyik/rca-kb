module TopModule #(
    parameter WIDTH = 8,
    parameter DEPTH = 16
)(
    input clk,
    input rst_n,
    input winc,
    input rinc,
    input [WIDTH-1:0] wdata,
    output wfull,
    output rempty,
    output wire [WIDTH-1:0] rdata
);

localparam ADDR_WIDTH = (DEPTH > 1) ? $clog2(DEPTH) : 1;
localparam [ADDR_WIDTH-1:0] LAST_ADDR = ADDR_WIDTH'(DEPTH - 1);

reg [ADDR_WIDTH:0] write_ptr;
reg [ADDR_WIDTH:0] read_ptr;
wire [ADDR_WIDTH-1:0] write_addr = write_ptr[ADDR_WIDTH-1:0];
wire [ADDR_WIDTH-1:0] read_addr = read_ptr[ADDR_WIDTH-1:0];
wire wenc = rst_n && winc && !wfull;
wire renc = rst_n && rinc && !rempty;

// Equal addresses indicate full or empty according to the wrap bits.
assign rempty = (write_ptr == read_ptr);
assign wfull = (write_addr == read_addr) &&
               (write_ptr[ADDR_WIDTH] != read_ptr[ADDR_WIDTH]);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        write_ptr <= 0;
    else if (wenc) begin
        if (write_addr == LAST_ADDR)
            write_ptr <= {~write_ptr[ADDR_WIDTH], {ADDR_WIDTH{1'b0}}};
        else
            write_ptr <= write_ptr + 1'b1;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        read_ptr <= 0;
    else if (renc) begin
        if (read_addr == LAST_ADDR)
            read_ptr <= {~read_ptr[ADDR_WIDTH], {ADDR_WIDTH{1'b0}}};
        else
            read_ptr <= read_ptr + 1'b1;
    end
end

dual_port_RAM #(.DEPTH(DEPTH), .WIDTH(WIDTH)) u_ram (
    .wclk(clk),
    .wenc(wenc),
    .waddr(write_addr),
    .wdata(wdata),
    .rclk(clk),
    .renc(renc),
    .raddr(read_addr),
    .rdata(rdata)
);

endmodule

/**********************************RAM************************************/

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
