module TopModule #(
    parameter WIDTH = 8,
    parameter DEPTH = 16
)(
    input                   clk,
    input                   rst_n,
    input                   winc,
    input                   rinc,
    input  [WIDTH-1:0]      wdata,
    output                  wfull,
    output                  rempty,
    output wire [WIDTH-1:0] rdata
);

localparam ADDR_WIDTH = (DEPTH > 1) ? $clog2(DEPTH) : 1;
localparam [ADDR_WIDTH-1:0] LAST_ADDR = ADDR_WIDTH'(DEPTH - 1);

reg [ADDR_WIDTH-1:0] waddr, raddr;
reg write_wrap, read_wrap;
wire same_addr = (waddr == raddr);

assign rempty = same_addr && (write_wrap == read_wrap);
assign wfull  = same_addr && (write_wrap != read_wrap);

wire wenc = rst_n && winc && !wfull;
wire renc = rst_n && rinc && !rempty;

// Each pointer toggles its wrap bit on advancing past the last RAM address.
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        waddr <= 0;
        raddr <= 0;
        write_wrap <= 0;
        read_wrap <= 0;
    end else begin
        if (wenc) begin
            if (waddr == LAST_ADDR) begin
                waddr <= 0;
                write_wrap <= ~write_wrap;
            end else begin
                waddr <= waddr + 1'b1;
            end
        end

        if (renc) begin
            if (raddr == LAST_ADDR) begin
                raddr <= 0;
                read_wrap <= ~read_wrap;
            end else begin
                raddr <= raddr + 1'b1;
            end
        end
    end
end

dual_port_RAM #(.DEPTH(DEPTH), .WIDTH(WIDTH)) u_ram (
    .wclk  (clk),
    .wenc  (wenc),
    .waddr (waddr),
    .wdata (wdata),
    .rclk  (clk),
    .renc  (renc),
    .raddr (raddr),
    .rdata (rdata)
);

endmodule

/**********************************RAM************************************/
module dual_port_RAM #(parameter DEPTH = 16,
					   parameter WIDTH = 8)(
	 input wclk
	,input wenc
	,input [((DEPTH > 1) ? $clog2(DEPTH) : 1)-1:0] waddr
	,input [WIDTH-1:0] wdata      	//Data write
	,input rclk
	,input renc
	,input [((DEPTH > 1) ? $clog2(DEPTH) : 1)-1:0] raddr
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
