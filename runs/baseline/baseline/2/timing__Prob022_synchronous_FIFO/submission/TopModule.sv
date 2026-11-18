module TopModule #(
    parameter WIDTH = 8,
    parameter DEPTH = 16
)(
    input                  clk,
    input                  rst_n,
    input                  winc,
    input                  rinc,
    input      [WIDTH-1:0] wdata,
    output                 wfull,
    output                 rempty,
    output wire [WIDTH-1:0] rdata
);

// The RAM interface requires at least two entries for a one-bit address.
localparam RAM_DEPTH = (DEPTH == 1) ? 2 : DEPTH;
localparam ADDR_WIDTH = $clog2(RAM_DEPTH);
localparam [ADDR_WIDTH-1:0] LAST_ADDR = ADDR_WIDTH'(DEPTH - 1);

reg [ADDR_WIDTH-1:0] waddr, raddr;
reg wwrap, rwrap;
wire wenc, renc;

// Equal addresses indicate full or empty depending on the wrap bits.
assign wfull  = (waddr == raddr) && (wwrap != rwrap);
assign rempty = (waddr == raddr) && (wwrap == rwrap);
assign wenc = rst_n && winc && !wfull;
assign renc = rst_n && rinc && !rempty;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        waddr <= 0;
        wwrap <= 0;
        raddr <= 0;
        rwrap <= 0;
    end else begin
        if (wenc) begin
            if (waddr == LAST_ADDR) begin
                waddr <= 0;
                wwrap <= ~wwrap;
            end else begin
                waddr <= waddr + 1'b1;
            end
        end
        if (renc) begin
            if (raddr == LAST_ADDR) begin
                raddr <= 0;
                rwrap <= ~rwrap;
            end else begin
                raddr <= raddr + 1'b1;
            end
        end
    end
end

dual_port_RAM #(.DEPTH(RAM_DEPTH), .WIDTH(WIDTH)) u_ram (
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
