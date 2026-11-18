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
    output wire             wfull,
    output wire             rempty,
    output wire [WIDTH-1:0] rdata
);

parameter ADDR_WIDTH = $clog2(DEPTH);
localparam RAM_ADDR_WIDTH = $clog2(DEPTH);
localparam PTR_WIDTH = 1 + (ADDR_WIDTH < RAM_ADDR_WIDTH ? RAM_ADDR_WIDTH : ADDR_WIDTH);

wire wen = wrstn && winc && !wfull;
wire ren = rrstn && rinc && !rempty;

reg  [PTR_WIDTH-1:0] waddr_bin, raddr_bin;
reg  [PTR_WIDTH-1:0] wptr, rptr;
wire [PTR_WIDTH-1:0] waddr_next = waddr_bin + wen;
wire [PTR_WIDTH-1:0] raddr_next = raddr_bin + ren;

// Register the Gray pointer on the same edge as the accepted RAM operation.
always @(posedge wclk or negedge wrstn) begin
    if (!wrstn) begin
        waddr_bin <= '0;
        wptr <= '0;
    end else begin
        waddr_bin <= waddr_next;
        wptr <= waddr_next ^ (waddr_next >> 1);
    end
end

always @(posedge rclk or negedge rrstn) begin
    if (!rrstn) begin
        raddr_bin <= '0;
        rptr <= '0;
    end else begin
        raddr_bin <= raddr_next;
        rptr <= raddr_next ^ (raddr_next >> 1);
    end
end

(* ASYNC_REG = "TRUE" *) reg [PTR_WIDTH-1:0] rptr_buff, rptr_syn;
(* ASYNC_REG = "TRUE" *) reg [PTR_WIDTH-1:0] wptr_buff, wptr_syn;

always @(posedge wclk or negedge wrstn) begin
    if (!wrstn) begin
        rptr_buff <= '0;
        rptr_syn <= '0;
    end else begin
        rptr_buff <= rptr;
        rptr_syn <= rptr_buff;
    end
end

always @(posedge rclk or negedge rrstn) begin
    if (!rrstn) begin
        wptr_buff <= '0;
        wptr_syn <= '0;
    end else begin
        wptr_buff <= wptr;
        wptr_syn <= wptr_buff;
    end
end

// The FIFO is full when the synchronized read pointer is DEPTH entries behind.
wire [PTR_WIDTH-1:0] full_read_bin = waddr_bin - PTR_WIDTH'(DEPTH);
assign wfull = (rptr_syn == (full_read_bin ^ (full_read_bin >> 1)));
assign rempty = (rptr == wptr_syn);

wire [RAM_ADDR_WIDTH-1:0] waddr, raddr;
generate
    if (DEPTH == 1) begin : single_entry
        assign waddr = '0;
        assign raddr = '0;
    end else if ((DEPTH & (DEPTH - 1)) == 0) begin : power_of_two_depth
        assign waddr = waddr_bin[RAM_ADDR_WIDTH-1:0];
        assign raddr = raddr_bin[RAM_ADDR_WIDTH-1:0];
    end else begin : other_depth
        // RAM addresses wrap at DEPTH while the Gray pointer keeps its full cycle.
        localparam [RAM_ADDR_WIDTH-1:0] LAST_ADDR = RAM_ADDR_WIDTH'(DEPTH - 1);
        reg [RAM_ADDR_WIDTH-1:0] write_addr, read_addr;

        always @(posedge wclk or negedge wrstn) begin
            if (!wrstn)
                write_addr <= '0;
            else if (wen)
                write_addr <= write_addr == LAST_ADDR ? '0 : write_addr + 1'b1;
        end

        always @(posedge rclk or negedge rrstn) begin
            if (!rrstn)
                read_addr <= '0;
            else if (ren)
                read_addr <= read_addr == LAST_ADDR ? '0 : read_addr + 1'b1;
        end

        assign waddr = write_addr;
        assign raddr = read_addr;
    end
endgenerate

dual_port_RAM #(.DEPTH(DEPTH), .WIDTH(WIDTH)) dual_port_RAM(
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
