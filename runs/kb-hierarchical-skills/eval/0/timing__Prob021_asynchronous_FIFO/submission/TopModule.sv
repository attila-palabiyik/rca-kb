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
localparam INDEX_WIDTH = (ADDR_WIDTH > 0) ? ADDR_WIDTH : 1;
// The supplied RAM declares a two-bit [-1:0] address port at depth one.
localparam RAM_ADDR_WIDTH = (DEPTH == 1) ? 2 : $clog2(DEPTH);
localparam [INDEX_WIDTH-1:0] LAST_ADDR = DEPTH - 1;

reg [INDEX_WIDTH:0] waddr_bin, raddr_bin;
reg [INDEX_WIDTH:0] wptr, rptr;
(* ASYNC_REG = "TRUE" *) reg [INDEX_WIDTH:0] rptr_buff, rptr_syn;
(* ASYNC_REG = "TRUE" *) reg [INDEX_WIDTH:0] wptr_buff, wptr_syn;

wire wen = wrstn && winc && !wfull;
wire ren = rrstn && rinc && !rempty;
wire [INDEX_WIDTH:0] waddr_next = advance(waddr_bin);
wire [INDEX_WIDTH:0] raddr_next = advance(raddr_bin);
wire [RAM_ADDR_WIDTH-1:0] waddr = waddr_bin[INDEX_WIDTH-1:0];
wire [RAM_ADDR_WIDTH-1:0] raddr = raddr_bin[INDEX_WIDTH-1:0];

function automatic [INDEX_WIDTH:0] advance(input [INDEX_WIDTH:0] pointer);
    if (pointer[INDEX_WIDTH-1:0] == LAST_ADDR)
        advance = {~pointer[INDEX_WIDTH], {INDEX_WIDTH{1'b0}}};
    else
        advance = pointer + 1'b1;
endfunction

function automatic [INDEX_WIDTH:0] to_gray(input [INDEX_WIDTH:0] pointer);
    reg [INDEX_WIDTH-1:0] index;
    begin
        // Reverse the Gray sequence on alternate laps so wrapping changes
        // only the phase bit, including at non-power-of-two depths.
        index = pointer[INDEX_WIDTH-1:0];
        if (pointer[INDEX_WIDTH])
            index = LAST_ADDR - index;
        to_gray = {pointer[INDEX_WIDTH], index ^ (index >> 1)};
    end
endfunction

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

assign wfull = rptr_syn == to_gray({~waddr_bin[INDEX_WIDTH], waddr_bin[INDEX_WIDTH-1:0]});
assign rempty = rptr == wptr_syn;

dual_port_RAM #(
    .DEPTH (DEPTH),
    .WIDTH (WIDTH)
) ram (
    .wclk  (wclk),
    .wenc  (wen),
    .waddr (waddr),
    .wdata (wdata),
    .rclk  (rclk),
    .renc  (ren),
    .raddr (raddr),
    .rdata (rdata)
);

endmodule
