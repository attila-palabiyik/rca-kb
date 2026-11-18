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

// A power-of-two address ring keeps Gray transitions single-bit at wraparound.
// For other depths, the full flag limits how many slots can be occupied.
localparam RAM_ADDR_WIDTH = (ADDR_WIDTH < 1) ? 1 : ADDR_WIDTH;
localparam RAM_DEPTH = 2 ** RAM_ADDR_WIDTH;
localparam [RAM_ADDR_WIDTH:0] CAPACITY = (RAM_ADDR_WIDTH + 1)'(DEPTH);

reg [RAM_ADDR_WIDTH:0] waddr_bin, raddr_bin;
reg [RAM_ADDR_WIDTH:0] wptr, rptr;

(* ASYNC_REG = "TRUE" *) reg [RAM_ADDR_WIDTH:0] rptr_buff, rptr_syn;
(* ASYNC_REG = "TRUE" *) reg [RAM_ADDR_WIDTH:0] wptr_buff, wptr_syn;

wire wen = wrstn && winc && !wfull;
wire ren = rrstn && rinc && !rempty;

function automatic [RAM_ADDR_WIDTH:0] to_gray(input [RAM_ADDR_WIDTH:0] binary);
    to_gray = binary ^ (binary >> 1);
endfunction

wire [RAM_ADDR_WIDTH:0] waddr_next = waddr_bin + 1'b1;
wire [RAM_ADDR_WIDTH:0] raddr_next = raddr_bin + 1'b1;

always @(posedge wclk or negedge wrstn) begin
    if (!wrstn) begin
        waddr_bin <= '0;
        wptr <= '0;
    end else if (wen) begin
        waddr_bin <= waddr_next;
        wptr <= to_gray(waddr_next);
    end
end

always @(posedge rclk or negedge rrstn) begin
    if (!rrstn) begin
        raddr_bin <= '0;
        rptr <= '0;
    end else if (ren) begin
        raddr_bin <= raddr_next;
        rptr <= to_gray(raddr_next);
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

generate
    if (DEPTH == RAM_DEPTH) begin : power_of_two_depth
        // One full lap flips the top two Gray bits.
        localparam [RAM_ADDR_WIDTH:0] FULL_MASK = 2'b11 << (RAM_ADDR_WIDTH - 1);
        assign wfull = (wptr == (rptr_syn ^ FULL_MASK));
    end else begin : limited_depth
        wire [RAM_ADDR_WIDTH:0] full_read_addr = waddr_bin - CAPACITY;
        assign wfull = (rptr_syn == to_gray(full_read_addr));
    end
endgenerate

assign rempty = (rptr == wptr_syn);

dual_port_RAM #(
    .DEPTH(RAM_DEPTH),
    .WIDTH(WIDTH)
) dual_port_RAM (
    .wclk(wclk),
    .wenc(wen),
    .waddr(waddr_bin[RAM_ADDR_WIDTH-1:0]),
    .wdata(wdata),
    .rclk(rclk),
    .renc(ren),
    .raddr(raddr_bin[RAM_ADDR_WIDTH-1:0]),
    .rdata(rdata)
);

endmodule
