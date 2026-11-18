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
    output reg wfull,
    output reg rempty,
    output wire [WIDTH-1:0] rdata
);

localparam ADDR_WIDTH = $clog2(DEPTH);
localparam [ADDR_WIDTH:0] FIFO_DEPTH = (ADDR_WIDTH+1)'(DEPTH);

reg [ADDR_WIDTH:0] waddr_bin, raddr_bin;
reg [ADDR_WIDTH:0] wptr, rptr;
(* ASYNC_REG = "TRUE" *) reg [ADDR_WIDTH:0] rptr_buff, rptr_syn;
(* ASYNC_REG = "TRUE" *) reg [ADDR_WIDTH:0] wptr_buff, wptr_syn;

wire wen = wrstn && winc && !wfull;
wire ren = rrstn && rinc && !rempty;
wire [ADDR_WIDTH:0] waddr_bin_next = waddr_bin + wen;
wire [ADDR_WIDTH:0] raddr_bin_next = raddr_bin + ren;
wire [ADDR_WIDTH:0] wptr_next = waddr_bin_next ^ (waddr_bin_next >> 1);
wire [ADDR_WIDTH:0] rptr_next = raddr_bin_next ^ (raddr_bin_next >> 1);

// Full when the synchronized read pointer is DEPTH entries behind
// the next write pointer, with subtraction modulo the pointer range.
wire [ADDR_WIDTH:0] full_read_bin = waddr_bin_next - FIFO_DEPTH;
wire [ADDR_WIDTH:0] full_read_gray = full_read_bin ^ (full_read_bin >> 1);

always @(posedge wclk or negedge wrstn) begin
    if (!wrstn) begin
        waddr_bin <= '0;
        wptr <= '0;
        wfull <= 1'b0;
        rptr_buff <= '0;
        rptr_syn <= '0;
    end else begin
        waddr_bin <= waddr_bin_next;
        wptr <= wptr_next;
        wfull <= (rptr_syn == full_read_gray);
        rptr_buff <= rptr;
        rptr_syn <= rptr_buff;
    end
end

always @(posedge rclk or negedge rrstn) begin
    if (!rrstn) begin
        raddr_bin <= '0;
        rptr <= '0;
        rempty <= 1'b1;
        wptr_buff <= '0;
        wptr_syn <= '0;
    end else begin
        raddr_bin <= raddr_bin_next;
        rptr <= rptr_next;
        rempty <= (wptr_syn == rptr_next);
        wptr_buff <= wptr;
        wptr_syn <= wptr_buff;
    end
end

wire [ADDR_WIDTH-1:0] waddr, raddr;
generate
    if (DEPTH == 1) begin : single_entry
        assign waddr = '0;
        assign raddr = '0;
    end else if ((DEPTH & (DEPTH - 1)) == 0) begin : power_of_two_depth
        assign waddr = waddr_bin[ADDR_WIDTH-1:0];
        assign raddr = raddr_bin[ADDR_WIDTH-1:0];
    end else begin : other_depth
        // Keep the CDC pointers free-running so every Gray transition
        // changes one bit. Wrap only the physical RAM addresses at DEPTH.
        localparam [ADDR_WIDTH-1:0] LAST_ADDR = ADDR_WIDTH'(DEPTH - 1);
        reg [ADDR_WIDTH-1:0] write_index, read_index;

        always @(posedge wclk or negedge wrstn) begin
            if (!wrstn)
                write_index <= '0;
            else if (wen)
                write_index <= (write_index == LAST_ADDR) ? '0 : write_index + 1'b1;
        end

        always @(posedge rclk or negedge rrstn) begin
            if (!rrstn)
                read_index <= '0;
            else if (ren)
                read_index <= (read_index == LAST_ADDR) ? '0 : read_index + 1'b1;
        end

        assign waddr = write_index;
        assign raddr = read_index;
    end
endgenerate

dual_port_RAM #(
    .DEPTH(DEPTH),
    .WIDTH(WIDTH)
) dual_port_RAM (
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
