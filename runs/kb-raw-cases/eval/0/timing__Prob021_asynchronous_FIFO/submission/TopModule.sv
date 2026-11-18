module TopModule #(
    parameter WIDTH = 8,
    parameter DEPTH = 16
)(
    input wire wclk,
    input wire rclk,
    input wire wrstn,
    input wire rrstn,
    input wire winc,
    input wire rinc,
    input wire [WIDTH-1:0] wdata,
    output wire wfull,
    output wire rempty,
    output wire [WIDTH-1:0] rdata
);

parameter ADDR_WIDTH = $clog2(DEPTH);
localparam RAM_ADDR_WIDTH = $clog2(DEPTH);
localparam [ADDR_WIDTH:0] CAPACITY = (ADDR_WIDTH+1)'(DEPTH);

reg [ADDR_WIDTH:0] waddr_bin, raddr_bin;
reg [ADDR_WIDTH:0] wptr, rptr;
(* ASYNC_REG = "TRUE" *) reg [ADDR_WIDTH:0] rptr_buff, rptr_syn;
(* ASYNC_REG = "TRUE" *) reg [ADDR_WIDTH:0] wptr_buff, wptr_syn;

wire wen = wrstn && winc && !wfull;
wire ren = rrstn && rinc && !rempty;
wire [ADDR_WIDTH:0] waddr_next = waddr_bin + 1'b1;
wire [ADDR_WIDTH:0] raddr_next = raddr_bin + 1'b1;

// Register the Gray encoding of the same position as the binary pointer.
always @(posedge wclk or negedge wrstn) begin
    if (!wrstn) begin
        waddr_bin <= '0;
        wptr <= '0;
    end else if (wen) begin
        waddr_bin <= waddr_next;
        wptr <= waddr_next ^ (waddr_next >> 1);
    end
end

always @(posedge rclk or negedge rrstn) begin
    if (!rrstn) begin
        raddr_bin <= '0;
        rptr <= '0;
    end else if (ren) begin
        raddr_bin <= raddr_next;
        rptr <= raddr_next ^ (raddr_next >> 1);
    end
end

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

// Full means the synchronized read position is DEPTH entries behind.
wire [ADDR_WIDTH:0] full_read_bin = waddr_bin - CAPACITY;
assign wfull = (rptr_syn == (full_read_bin ^ (full_read_bin >> 1)));
assign rempty = (rptr == wptr_syn);

wire [RAM_ADDR_WIDTH-1:0] waddr, raddr;
generate
    if (DEPTH == 1) begin : single_entry
        assign waddr = '0;
        assign raddr = '0;
    end else if ((DEPTH & (DEPTH - 1)) == 0) begin : power_of_two
        assign waddr = waddr_bin[RAM_ADDR_WIDTH-1:0];
        assign raddr = raddr_bin[RAM_ADDR_WIDTH-1:0];
    end else begin : wrapped_addresses
        // RAM addresses wrap at DEPTH, while the CDC counters wrap at a
        // power of two so the Gray code changes one bit at every increment.
        localparam [RAM_ADDR_WIDTH-1:0] LAST_ADDR = RAM_ADDR_WIDTH'(DEPTH - 1);
        reg [RAM_ADDR_WIDTH-1:0] write_addr, read_addr;
        assign waddr = write_addr;
        assign raddr = read_addr;

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
    end
endgenerate

dual_port_RAM #(.DEPTH(DEPTH), .WIDTH(WIDTH)) dual_port_RAM (
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
