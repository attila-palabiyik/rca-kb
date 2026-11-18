module TopModule #(
    parameter WIDTH = 8,
    parameter DEPTH = 16
)(
    input                   wclk,
    input                   rclk,
    input                   wrstn,
    input                   rrstn,
    input                   winc,
    input                   rinc,
    input      [WIDTH-1:0]  wdata,
    output wire             wfull,
    output wire             rempty,
    output wire [WIDTH-1:0] rdata
);

localparam ADDR_WIDTH = (DEPTH > 1) ? $clog2(DEPTH) : 1;
localparam PTR_WIDTH = ADDR_WIDTH + 1;
localparam [PTR_WIDTH-1:0] CAPACITY = PTR_WIDTH'(DEPTH);
localparam [ADDR_WIDTH-1:0] LAST_ADDR = ADDR_WIDTH'(DEPTH - 1);

reg [PTR_WIDTH-1:0] wbin, rbin;
reg [PTR_WIDTH-1:0] wgray, rgray;
(* ASYNC_REG = "TRUE" *) reg [PTR_WIDTH-1:0] rgray_meta, rgray_sync;
(* ASYNC_REG = "TRUE" *) reg [PTR_WIDTH-1:0] wgray_meta, wgray_sync;
wire [ADDR_WIDTH-1:0] waddr, raddr;

wire wen = wrstn && winc && !wfull;
wire ren = rrstn && rinc && !rempty;
wire [PTR_WIDTH-1:0] wbin_next = wbin + PTR_WIDTH'(wen);
wire [PTR_WIDTH-1:0] rbin_next = rbin + PTR_WIDTH'(ren);

// Register the Gray value and its binary pointer on the same clock edge.
always @(posedge wclk or negedge wrstn) begin
    if (!wrstn) begin
        wbin <= '0;
        wgray <= '0;
    end else begin
        wbin <= wbin_next;
        wgray <= wbin_next ^ (wbin_next >> 1);
    end
end

always @(posedge rclk or negedge rrstn) begin
    if (!rrstn) begin
        rbin <= '0;
        rgray <= '0;
    end else begin
        rbin <= rbin_next;
        rgray <= rbin_next ^ (rbin_next >> 1);
    end
end

always @(posedge wclk or negedge wrstn) begin
    if (!wrstn) begin
        rgray_meta <= '0;
        rgray_sync <= '0;
    end else begin
        rgray_meta <= rgray;
        rgray_sync <= rgray_meta;
    end
end

always @(posedge rclk or negedge rrstn) begin
    if (!rrstn) begin
        wgray_meta <= '0;
        wgray_sync <= '0;
    end else begin
        wgray_meta <= wgray;
        wgray_sync <= wgray_meta;
    end
end

assign rempty = (rgray == wgray_sync);

generate
    if ((DEPTH > 1) && (DEPTH == (2 ** ADDR_WIDTH))) begin : power_of_two
        // One RAM length ahead flips the two high bits of the Gray pointer.
        localparam [PTR_WIDTH-1:0] FULL_MASK =
            {2'b11, {(PTR_WIDTH-2){1'b0}}};

        assign wfull = (wgray == (rgray_sync ^ FULL_MASK));
        assign waddr = wbin[ADDR_WIDTH-1:0];
        assign raddr = rbin[ADDR_WIDTH-1:0];
    end else begin : explicit_wrap
        reg [ADDR_WIDTH-1:0] waddr_reg, raddr_reg;
        wire [PTR_WIDTH-1:0] rbin_sync;
        wire [PTR_WIDTH-1:0] full_at = rbin_sync + CAPACITY;

        // Keep the Gray counters on their power-of-two cycle for CDC.
        // RAM addresses wrap separately at the configured depth.
        assign rbin_sync[PTR_WIDTH-1] = rgray_sync[PTR_WIDTH-1];
        for (genvar bit_idx = 0; bit_idx < PTR_WIDTH-1; bit_idx = bit_idx + 1) begin : decode
            assign rbin_sync[bit_idx] = rbin_sync[bit_idx+1] ^ rgray_sync[bit_idx];
        end
        assign wfull = (wbin == full_at);
        assign waddr = waddr_reg;
        assign raddr = raddr_reg;

        always @(posedge wclk or negedge wrstn) begin
            if (!wrstn)
                waddr_reg <= '0;
            else if (wen)
                waddr_reg <= (waddr_reg == LAST_ADDR) ? '0 : waddr_reg + 1'b1;
        end

        always @(posedge rclk or negedge rrstn) begin
            if (!rrstn)
                raddr_reg <= '0;
            else if (ren)
                raddr_reg <= (raddr_reg == LAST_ADDR) ? '0 : raddr_reg + 1'b1;
        end
    end
endgenerate

dual_port_RAM #(.DEPTH(DEPTH), .WIDTH(WIDTH)) ram (
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

module dual_port_RAM #(
    parameter DEPTH = 16,
    parameter WIDTH = 8
)(
    input wclk,
    input wenc,
    input [((DEPTH > 1) ? $clog2(DEPTH) : 1)-1:0] waddr,
    input [WIDTH-1:0] wdata,
    input rclk,
    input renc,
    input [((DEPTH > 1) ? $clog2(DEPTH) : 1)-1:0] raddr,
    output reg [WIDTH-1:0] rdata
);

reg [WIDTH-1:0] RAM_MEM [0:DEPTH-1];

always @(posedge wclk) begin
    if (wenc)
        RAM_MEM[waddr] <= wdata;
end

always @(posedge rclk) begin
    if (renc)
        rdata <= RAM_MEM[raddr];
end

endmodule
