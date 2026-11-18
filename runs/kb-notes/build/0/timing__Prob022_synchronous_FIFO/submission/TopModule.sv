module TopModule #(
    parameter WIDTH = 8,
    parameter DEPTH = 16
) (
    input  wire             clk,
    input  wire             rst_n,
    input  wire             winc,
    input  wire             rinc,
    input  wire [WIDTH-1:0] wdata,
    output wire             wfull,
    output wire             rempty,
    output wire [WIDTH-1:0] rdata
);

localparam RAM_ADDR_BITS = $clog2(DEPTH);
localparam ADDR_BITS = (DEPTH == 1) ? 1 : RAM_ADDR_BITS;
localparam [ADDR_BITS-1:0] LAST_ADDR = ADDR_BITS'(DEPTH - 1);

// The high bit toggles each time a pointer wraps around the RAM.
reg [ADDR_BITS:0] wptr;
reg [ADDR_BITS:0] rptr;
wire [ADDR_BITS-1:0] waddr = wptr[ADDR_BITS-1:0];
wire [ADDR_BITS-1:0] raddr = rptr[ADDR_BITS-1:0];

assign rempty = (wptr == rptr);
assign wfull = (waddr == raddr) && (wptr[ADDR_BITS] != rptr[ADDR_BITS]);

wire wenc = rst_n && winc && !wfull;
wire renc = rst_n && rinc && !rempty;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        wptr <= 0;
        rptr <= 0;
    end else begin
        if (wenc) begin
            if (waddr == LAST_ADDR)
                wptr <= {~wptr[ADDR_BITS], {ADDR_BITS{1'b0}}};
            else
                wptr <= wptr + 1'b1;
        end

        if (renc) begin
            if (raddr == LAST_ADDR)
                rptr <= {~rptr[ADDR_BITS], {ADDR_BITS{1'b0}}};
            else
                rptr <= rptr + 1'b1;
        end
    end
end

// Match the RAM port ranges, including its [-1:0] range at DEPTH=1.
wire [RAM_ADDR_BITS-1:0] ram_waddr = waddr;
wire [RAM_ADDR_BITS-1:0] ram_raddr = raddr;

dual_port_RAM #(.DEPTH(DEPTH), .WIDTH(WIDTH)) u_ram (
    .wclk  (clk),
    .wenc  (wenc),
    .waddr (ram_waddr),
    .wdata (wdata),
    .rclk  (clk),
    .renc  (renc),
    .raddr (ram_raddr),
    .rdata (rdata)
);

endmodule
