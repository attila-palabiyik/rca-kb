module TopModule #(
    parameter WIDTH = 8,
    parameter DEPTH = 16
)(
    input wclk,
    input rclk,
    input wrstn,
    input rrstn,
    input winc,
    input rinc,
    input [WIDTH-1:0] wdata,
    output wire wfull,
    output wire rempty,
    output wire [WIDTH-1:0] rdata
);

parameter ADDR_WIDTH = $clog2(DEPTH);
localparam [ADDR_WIDTH:0] DEPTH_COUNT = DEPTH;
localparam POWER_OF_TWO_DEPTH = (DEPTH & (DEPTH - 1)) == 0;

reg [ADDR_WIDTH:0] waddr_bin;
reg [ADDR_WIDTH:0] raddr_bin;
reg [ADDR_WIDTH:0] wptr;
reg [ADDR_WIDTH:0] rptr;

(* ASYNC_REG = "TRUE" *) reg [ADDR_WIDTH:0] rptr_buff, rptr_syn;
(* ASYNC_REG = "TRUE" *) reg [ADDR_WIDTH:0] wptr_buff, wptr_syn;

wire wen = wrstn && winc && !wfull;
wire ren = rrstn && rinc && !rempty;
wire [ADDR_WIDTH:0] waddr_next = waddr_bin + 1'b1;
wire [ADDR_WIDTH:0] raddr_next = raddr_bin + 1'b1;

// Publish the Gray encoding on the same edge that advances the RAM pointer.
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

assign rempty = (rptr == wptr_syn);

wire [ADDR_WIDTH-1:0] waddr;
wire [ADDR_WIDTH-1:0] raddr;

generate
    if (POWER_OF_TWO_DEPTH) begin : gray_full
        localparam [ADDR_WIDTH:0] FULL_MASK = DEPTH_COUNT ^ (DEPTH_COUNT >> 1);
        assign wfull = (wptr == (rptr_syn ^ FULL_MASK));
    end else begin : depth_full
        wire [ADDR_WIDTH:0] full_read_bin = waddr_bin - DEPTH_COUNT;
        assign wfull = (rptr_syn == (full_read_bin ^ (full_read_bin >> 1)));
    end

    if (DEPTH == 1) begin : single_slot
        assign waddr = '0;
        assign raddr = '0;
    end else if (POWER_OF_TWO_DEPTH) begin : power_of_two
        assign waddr = waddr_bin[ADDR_WIDTH-1:0];
        assign raddr = raddr_bin[ADDR_WIDTH-1:0];
    end else begin : explicit_address_wrap
        // Keep the CDC pointers on their power-of-two Gray cycle while
        // the RAM addresses wrap at the configured depth.
        localparam [ADDR_WIDTH-1:0] LAST_ADDR = DEPTH - 1;
        reg [ADDR_WIDTH-1:0] write_addr;
        reg [ADDR_WIDTH-1:0] read_addr;

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
