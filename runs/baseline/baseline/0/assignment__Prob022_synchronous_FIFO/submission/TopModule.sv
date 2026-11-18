module TopModule#(
	parameter	WIDTH = 8,
	parameter 	DEPTH = 16
)(
	input 					clk		, 
	input 					rst_n	,
	input 					winc	,
	input 			 		rinc	,
	input 		[WIDTH-1:0]	wdata	,
 
	output 				    wfull	,
	output 				    rempty	,
	output wire [WIDTH-1:0]	rdata
);
 
localparam DP_WD = (DEPTH > 1) ? $clog2(DEPTH) : 1;
localparam [DP_WD-1:0] LAST_ADDR = DP_WD'(DEPTH - 1);

reg [DP_WD:0] waddr;
reg [DP_WD:0] raddr;

wire same_addr = (waddr[DP_WD-1:0] == raddr[DP_WD-1:0]);
wire same_wrap = (waddr[DP_WD] == raddr[DP_WD]);
assign rempty = same_addr && same_wrap;
assign wfull = same_addr && !same_wrap;

wire wenc = rst_n && winc && !wfull;
wire renc = rst_n && rinc && !rempty;

// The extra bit toggles each time the RAM address wraps.
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        waddr <= 0;
        raddr <= 0;
    end else begin
        if (wenc) begin
            if (waddr[DP_WD-1:0] == LAST_ADDR)
                waddr <= {~waddr[DP_WD], {DP_WD{1'b0}}};
            else
                waddr <= waddr + 1'b1;
        end

        if (renc) begin
            if (raddr[DP_WD-1:0] == LAST_ADDR)
                raddr <= {~raddr[DP_WD], {DP_WD{1'b0}}};
            else
                raddr <= raddr + 1'b1;
        end
    end
end

dual_port_RAM #(.DEPTH(DEPTH), .WIDTH(WIDTH))
u_ram (
    .wclk  (clk),
    .wenc  (wenc),
    .waddr (waddr[DP_WD-1:0]),
    .wdata (wdata),
    .rclk  (clk),
    .renc  (renc),
    .raddr (raddr[DP_WD-1:0]),
    .rdata (rdata)
);

endmodule

/**********************************RAM************************************/
module dual_port_RAM #(parameter DEPTH = 16,
					   parameter WIDTH = 8)(
	 input wclk
	,input wenc
	,input [((DEPTH > 1) ? $clog2(DEPTH) : 1)-1:0] waddr  //Take log2 of depth to get address bit width.
	,input [WIDTH-1:0] wdata      	//Data write
	,input rclk
	,input renc
	,input [((DEPTH > 1) ? $clog2(DEPTH) : 1)-1:0] raddr  //Take log2 of depth to get address bit width.
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
