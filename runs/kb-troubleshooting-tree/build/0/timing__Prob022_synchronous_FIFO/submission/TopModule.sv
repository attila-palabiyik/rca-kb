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

// The RAM interface needs at least one address bit.
localparam RAM_DEPTH = (DEPTH == 1) ? 2 : DEPTH;
localparam ADDR_WIDTH = $clog2(RAM_DEPTH);
localparam [ADDR_WIDTH-1:0] LAST_ADDR = DEPTH - 1;

// The extra bit toggles each time a pointer wraps.
reg [ADDR_WIDTH:0] waddr;
reg [ADDR_WIDTH:0] raddr;

wire wenc = rst_n && winc && !wfull;
wire renc = rst_n && rinc && !rempty;

assign rempty = (waddr == raddr);
assign wfull = (waddr[ADDR_WIDTH] != raddr[ADDR_WIDTH]) &&
               (waddr[ADDR_WIDTH-1:0] == raddr[ADDR_WIDTH-1:0]);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        waddr <= 0;
    else if (wenc) begin
        if (waddr[ADDR_WIDTH-1:0] == LAST_ADDR)
            waddr <= {~waddr[ADDR_WIDTH], {ADDR_WIDTH{1'b0}}};
        else
            waddr <= waddr + 1'b1;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        raddr <= 0;
    else if (renc) begin
        if (raddr[ADDR_WIDTH-1:0] == LAST_ADDR)
            raddr <= {~raddr[ADDR_WIDTH], {ADDR_WIDTH{1'b0}}};
        else
            raddr <= raddr + 1'b1;
    end
end

dual_port_RAM #(.DEPTH(RAM_DEPTH), .WIDTH(WIDTH)) u_ram (
    .wclk(clk),
    .wenc(wenc),
    .waddr(waddr[ADDR_WIDTH-1:0]),
    .wdata(wdata),
    .rclk(clk),
    .renc(renc),
    .raddr(raddr[ADDR_WIDTH-1:0]),
    .rdata(rdata)
);

endmodule
