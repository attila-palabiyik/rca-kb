module TopModule #(
    parameter WIDTH = 8,
    parameter DEPTH = 16
)(
    input                  wclk,
    input                  rclk,
    input                  wrstn,
    input                  rrstn,
    input                  winc,
    input                  rinc,
    input      [WIDTH-1:0] wdata,
    output reg             wfull,
    output reg             rempty,
    output wire [WIDTH-1:0] rdata
);

parameter ADDR_WIDTH = $clog2(DEPTH);

localparam RAM_ADDR_WIDTH = (DEPTH > 1) ? $clog2(DEPTH) : 1;
localparam PTR_WIDTH = ((ADDR_WIDTH > RAM_ADDR_WIDTH) ? ADDR_WIDTH : RAM_ADDR_WIDTH) + 1;
localparam [PTR_WIDTH-1:0] CAPACITY = PTR_WIDTH'(DEPTH);
localparam [RAM_ADDR_WIDTH-1:0] LAST_ADDR = RAM_ADDR_WIDTH'(DEPTH - 1);

wire wen = wrstn && winc && !wfull;
wire ren = rrstn && rinc && !rempty;

reg [PTR_WIDTH-1:0] wbin, rbin;
reg [PTR_WIDTH-1:0] wptr, rptr;
(* ASYNC_REG = "TRUE" *) reg [PTR_WIDTH-1:0] rptr_meta, rptr_sync;
(* ASYNC_REG = "TRUE" *) reg [PTR_WIDTH-1:0] wptr_meta, wptr_sync;

wire [PTR_WIDTH-1:0] wbin_next = wbin + wen;
wire [PTR_WIDTH-1:0] rbin_next = rbin + ren;
wire [PTR_WIDTH-1:0] wptr_next = wbin_next ^ (wbin_next >> 1);
wire [PTR_WIDTH-1:0] rptr_next = rbin_next ^ (rbin_next >> 1);

// Full when the synchronized read pointer is DEPTH entries behind the next write pointer.
wire [PTR_WIDTH-1:0] full_rbin = wbin_next - CAPACITY;
wire [PTR_WIDTH-1:0] full_rptr = full_rbin ^ (full_rbin >> 1);

always @(posedge wclk or negedge wrstn) begin
    if (!wrstn) begin
        wbin <= '0;
        wptr <= '0;
        wfull <= 1'b0;
        rptr_meta <= '0;
        rptr_sync <= '0;
    end else begin
        wbin <= wbin_next;
        wptr <= wptr_next;
        wfull <= (full_rptr == rptr_sync);
        rptr_meta <= rptr;
        rptr_sync <= rptr_meta;
    end
end

always @(posedge rclk or negedge rrstn) begin
    if (!rrstn) begin
        rbin <= '0;
        rptr <= '0;
        rempty <= 1'b1;
        wptr_meta <= '0;
        wptr_sync <= '0;
    end else begin
        rbin <= rbin_next;
        rptr <= rptr_next;
        rempty <= (rptr_next == wptr_sync);
        wptr_meta <= wptr;
        wptr_sync <= wptr_meta;
    end
end

wire [RAM_ADDR_WIDTH-1:0] waddr, raddr;

generate
    if (DEPTH == 2**RAM_ADDR_WIDTH) begin : gen_binary_addresses
        assign waddr = wbin[RAM_ADDR_WIDTH-1:0];
        assign raddr = rbin[RAM_ADDR_WIDTH-1:0];
    end else begin : gen_wrapped_addresses
        // RAM addresses wrap at DEPTH. The CDC counters retain their full Gray cycle.
        reg [RAM_ADDR_WIDTH-1:0] write_addr, read_addr;

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
    input                                             wclk,
    input                                             wenc,
    input      [((DEPTH > 1) ? $clog2(DEPTH) : 1)-1:0] waddr,
    input      [WIDTH-1:0]                            wdata,
    input                                             rclk,
    input                                             renc,
    input      [((DEPTH > 1) ? $clog2(DEPTH) : 1)-1:0] raddr,
    output reg [WIDTH-1:0]                            rdata
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
