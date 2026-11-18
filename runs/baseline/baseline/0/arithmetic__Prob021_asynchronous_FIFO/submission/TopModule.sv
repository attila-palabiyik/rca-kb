module TopModule #(
    parameter WIDTH = 8,
    parameter DEPTH = 16
)(
    input  wire             wclk,
    input  wire             rclk,
    input  wire             wrstn,
    input  wire             rrstn,
    input  wire             winc,
    input  wire             rinc,
    input  wire [WIDTH-1:0] wdata,
    output reg              wfull,
    output reg              rempty,
    output wire [WIDTH-1:0] rdata
);

localparam ADDR_WIDTH = (DEPTH > 1) ? $clog2(DEPTH) : 1;
localparam PTR_WIDTH = $clog2(DEPTH) + 1;
localparam [PTR_WIDTH-1:0] CAPACITY = DEPTH;

reg [PTR_WIDTH-1:0] wbin, rbin;
reg [PTR_WIDTH-1:0] wgray, rgray;
(* ASYNC_REG = "TRUE" *) reg [PTR_WIDTH-1:0] rgray_wmeta, rgray_wsync;
(* ASYNC_REG = "TRUE" *) reg [PTR_WIDTH-1:0] wgray_rmeta, wgray_rsync;

wire wen = wrstn && winc && !wfull;
wire ren = rrstn && rinc && !rempty;
wire [PTR_WIDTH-1:0] wbin_next = wbin + wen;
wire [PTR_WIDTH-1:0] rbin_next = rbin + ren;
wire [PTR_WIDTH-1:0] wgray_next = wbin_next ^ (wbin_next >> 1);
wire [PTR_WIDTH-1:0] rgray_next = rbin_next ^ (rbin_next >> 1);

function automatic [PTR_WIDTH-1:0] gray_to_bin(input [PTR_WIDTH-1:0] gray);
    integer i;
    begin
        gray_to_bin[PTR_WIDTH-1] = gray[PTR_WIDTH-1];
        for (i = PTR_WIDTH-2; i >= 0; i = i - 1)
            gray_to_bin[i] = gray_to_bin[i+1] ^ gray[i];
    end
endfunction

wire [PTR_WIDTH-1:0] used_after_write = wbin_next - gray_to_bin(rgray_wsync);

// Assert both domain resets to flush the FIFO and restart its pointers.
always @(posedge wclk or negedge wrstn) begin
    if (!wrstn) begin
        wbin        <= '0;
        wgray       <= '0;
        rgray_wmeta <= '0;
        rgray_wsync <= '0;
        wfull       <= 1'b0;
    end else begin
        wbin        <= wbin_next;
        wgray       <= wgray_next;
        rgray_wmeta <= rgray;
        rgray_wsync <= rgray_wmeta;
        wfull       <= (used_after_write == CAPACITY);
    end
end

always @(posedge rclk or negedge rrstn) begin
    if (!rrstn) begin
        rbin        <= '0;
        rgray       <= '0;
        wgray_rmeta <= '0;
        wgray_rsync <= '0;
        rempty      <= 1'b1;
    end else begin
        rbin        <= rbin_next;
        rgray       <= rgray_next;
        wgray_rmeta <= wgray;
        wgray_rsync <= wgray_rmeta;
        rempty      <= (rgray_next == wgray_rsync);
    end
end

wire [ADDR_WIDTH-1:0] waddr, raddr;

// The Gray counters wrap at a power of two to preserve one-bit transitions.
// For other depths, local RAM addresses wrap at DEPTH independently.
generate
    if (DEPTH == 1) begin : single_entry
        assign waddr = '0;
        assign raddr = '0;
    end else if ((DEPTH & (DEPTH - 1)) == 0) begin : power_of_two
        assign waddr = wbin[ADDR_WIDTH-1:0];
        assign raddr = rbin[ADDR_WIDTH-1:0];
    end else begin : modulo_depth
        localparam [ADDR_WIDTH-1:0] LAST_ADDR = DEPTH - 1;
        reg [ADDR_WIDTH-1:0] write_addr, read_addr;

        always @(posedge wclk or negedge wrstn) begin
            if (!wrstn)
                write_addr <= '0;
            else if (wen)
                write_addr <= (write_addr == LAST_ADDR) ? '0 : write_addr + 1'b1;
        end

        always @(posedge rclk or negedge rrstn) begin
            if (!rrstn)
                read_addr <= '0;
            else if (ren)
                read_addr <= (read_addr == LAST_ADDR) ? '0 : read_addr + 1'b1;
        end

        assign waddr = write_addr;
        assign raddr = read_addr;
    end
endgenerate

dual_port_RAM #(
    .DEPTH(DEPTH),
    .WIDTH(WIDTH)
) fifo_ram (
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

module dual_port_RAM #(
    parameter DEPTH = 16,
    parameter WIDTH = 8,
    localparam ADDR_WIDTH = (DEPTH > 1) ? $clog2(DEPTH) : 1
)(
    input  wire                  wclk,
    input  wire                  wenc,
    input  wire [ADDR_WIDTH-1:0] waddr,
    input  wire [WIDTH-1:0]      wdata,
    input  wire                  rclk,
    input  wire                  renc,
    input  wire [ADDR_WIDTH-1:0] raddr,
    output reg  [WIDTH-1:0]      rdata
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
