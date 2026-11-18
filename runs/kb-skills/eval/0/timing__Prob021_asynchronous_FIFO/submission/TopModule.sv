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
    output wire            wfull,
    output wire            rempty,
    output wire [WIDTH-1:0] rdata
);

parameter ADDR_WIDTH = $clog2(DEPTH);
localparam PTR_ADDR_WIDTH = ADDR_WIDTH > 0 ? ADDR_WIDTH : 1;
// The supplied RAM declares a two-bit [-1:0] address when DEPTH is one.
localparam RAM_ADDR_WIDTH = DEPTH == 1 ? 2 : $clog2(DEPTH);
localparam [PTR_ADDR_WIDTH-1:0] LAST_ADDR = PTR_ADDR_WIDTH'(DEPTH - 1);
localparam [PTR_ADDR_WIDTH:0] WRAP_BIT = {1'b1, {PTR_ADDR_WIDTH{1'b0}}};

function automatic [PTR_ADDR_WIDTH:0] advance;
    input [PTR_ADDR_WIDTH:0] pointer;
    begin
        if (pointer[PTR_ADDR_WIDTH-1:0] == LAST_ADDR)
            advance = {(~pointer[PTR_ADDR_WIDTH]), {PTR_ADDR_WIDTH{1'b0}}};
        else
            advance = pointer + 1'b1;
    end
endfunction

function automatic [PTR_ADDR_WIDTH:0] gray;
    input [PTR_ADDR_WIDTH:0] pointer;
    reg [PTR_ADDR_WIDTH-1:0] address;
    begin
        // Traverse the address codes in reverse on the second lap so
        // that only the wrap bit changes at either end of the Gray sequence.
        address = pointer[PTR_ADDR_WIDTH-1:0];
        if (pointer[PTR_ADDR_WIDTH])
            address = LAST_ADDR - address;
        gray = {pointer[PTR_ADDR_WIDTH], address ^ (address >> 1)};
    end
endfunction

reg [PTR_ADDR_WIDTH:0] waddr_bin;
reg [PTR_ADDR_WIDTH:0] raddr_bin;
reg [PTR_ADDR_WIDTH:0] wptr;
reg [PTR_ADDR_WIDTH:0] rptr;
reg [PTR_ADDR_WIDTH:0] wfull_ptr;
wire [PTR_ADDR_WIDTH:0] waddr_next = advance(waddr_bin);
wire [PTR_ADDR_WIDTH:0] raddr_next = advance(raddr_bin);
wire wen = wrstn && winc && !wfull;
wire ren = rrstn && rinc && !rempty;

always @(posedge wclk or negedge wrstn) begin
    if (!wrstn) begin
        waddr_bin <= '0;
        wptr <= '0;
        wfull_ptr <= gray(WRAP_BIT);
    end else if (wen) begin
        waddr_bin <= waddr_next;
        wptr <= gray(waddr_next);
        wfull_ptr <= gray(waddr_next ^ WRAP_BIT);
    end
end

always @(posedge rclk or negedge rrstn) begin
    if (!rrstn) begin
        raddr_bin <= '0;
        rptr <= '0;
    end else if (ren) begin
        raddr_bin <= raddr_next;
        rptr <= gray(raddr_next);
    end
end

(* ASYNC_REG = "TRUE" *) reg [PTR_ADDR_WIDTH:0] rptr_buff, rptr_syn;
(* ASYNC_REG = "TRUE" *) reg [PTR_ADDR_WIDTH:0] wptr_buff, wptr_syn;

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

// Full matches the synchronized read pointer one complete lap away.
assign wfull = (wfull_ptr == rptr_syn);
assign rempty = (rptr == wptr_syn);

dual_port_RAM #(.DEPTH(DEPTH), .WIDTH(WIDTH)) dual_port_RAM (
    .wclk (wclk),
    .wenc (wen),
    .waddr(RAM_ADDR_WIDTH'(waddr_bin[PTR_ADDR_WIDTH-1:0])),
    .wdata(wdata),
    .rclk (rclk),
    .renc (ren),
    .raddr(RAM_ADDR_WIDTH'(raddr_bin[PTR_ADDR_WIDTH-1:0])),
    .rdata(rdata)
);

endmodule
