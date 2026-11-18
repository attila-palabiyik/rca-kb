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

parameter ADDR_WIDTH = (DEPTH > 1) ? $clog2(DEPTH) : 1;
localparam [ADDR_WIDTH-1:0] LAST_ADDR = ADDR_WIDTH'(DEPTH - 1);
localparam [ADDR_WIDTH:0] GRAY_OFFSET = (1 << ADDR_WIDTH) - DEPTH;

// The low bits address RAM. The high bit toggles after each lap.
function automatic [ADDR_WIDTH:0] advance_pointer(input [ADDR_WIDTH:0] pointer);
    if (pointer[ADDR_WIDTH-1:0] == LAST_ADDR)
        advance_pointer = {~pointer[ADDR_WIDTH], {ADDR_WIDTH{1'b0}}};
    else
        advance_pointer = pointer + 1'b1;
endfunction

// Center the 2*DEPTH positions on the reflected Gray code's midpoint.
// This keeps the first and last codes one bit apart at any depth.
function automatic [ADDR_WIDTH:0] gray_pointer(input [ADDR_WIDTH:0] pointer);
    reg [ADDR_WIDTH:0] position;
    begin
        position = GRAY_OFFSET + {1'b0, pointer[ADDR_WIDTH-1:0]};
        if (pointer[ADDR_WIDTH])
            position = position + (ADDR_WIDTH+1)'(DEPTH);
        gray_pointer = position ^ (position >> 1);
    end
endfunction

localparam [ADDR_WIDTH:0] ZERO_POINTER = '0;
localparam [ADDR_WIDTH:0] WRAP_BIT = {1'b1, {ADDR_WIDTH{1'b0}}};
localparam [ADDR_WIDTH:0] WRITE_RESET = gray_pointer(ZERO_POINTER);
localparam [ADDR_WIDTH:0] READ_FULL_RESET = gray_pointer(WRAP_BIT);

reg [ADDR_WIDTH:0] waddr_bin, raddr_bin;
reg [ADDR_WIDTH:0] wptr, rptr, rptr_full;
(* ASYNC_REG = "TRUE" *) reg [ADDR_WIDTH:0] wptr_buff, wptr_syn;
(* ASYNC_REG = "TRUE" *) reg [ADDR_WIDTH:0] rptr_full_buff, rptr_full_syn;

wire wen = wrstn && winc && !wfull;
wire ren = rrstn && rinc && !rempty;
wire [ADDR_WIDTH:0] waddr_next = advance_pointer(waddr_bin);
wire [ADDR_WIDTH:0] raddr_next = advance_pointer(raddr_bin);

always @(posedge wclk or negedge wrstn) begin
    if (!wrstn) begin
        waddr_bin <= ZERO_POINTER;
        wptr <= WRITE_RESET;
    end else if (wen) begin
        waddr_bin <= waddr_next;
        wptr <= gray_pointer(waddr_next);
    end
end

always @(posedge rclk or negedge rrstn) begin
    if (!rrstn) begin
        raddr_bin <= ZERO_POINTER;
        rptr <= WRITE_RESET;
        rptr_full <= READ_FULL_RESET;
    end else if (ren) begin
        raddr_bin <= raddr_next;
        rptr <= gray_pointer(raddr_next);
        // The write pointer reaches full one lap ahead of the read pointer.
        rptr_full <= gray_pointer(raddr_next ^ WRAP_BIT);
    end
end

always @(posedge wclk or negedge wrstn) begin
    if (!wrstn) begin
        rptr_full_buff <= READ_FULL_RESET;
        rptr_full_syn <= READ_FULL_RESET;
    end else begin
        rptr_full_buff <= rptr_full;
        rptr_full_syn <= rptr_full_buff;
    end
end

always @(posedge rclk or negedge rrstn) begin
    if (!rrstn) begin
        wptr_buff <= WRITE_RESET;
        wptr_syn <= WRITE_RESET;
    end else begin
        wptr_buff <= wptr;
        wptr_syn <= wptr_buff;
    end
end

assign wfull = (wptr == rptr_full_syn);
assign rempty = (rptr == wptr_syn);

dual_port_RAM #(.DEPTH(DEPTH), .WIDTH(WIDTH)) ram (
    .wclk  (wclk),
    .wenc  (wen),
    .waddr (waddr_bin[ADDR_WIDTH-1:0]),
    .wdata (wdata),
    .rclk  (rclk),
    .renc  (ren),
    .raddr (raddr_bin[ADDR_WIDTH-1:0]),
    .rdata (rdata)
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
