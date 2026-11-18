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

parameter ADDR_WIDTH = (DEPTH > 1) ? $clog2(DEPTH) : 1;

localparam [ADDR_WIDTH-1:0] LAST_ADDR = ADDR_WIDTH'(DEPTH - 1);

reg [ADDR_WIDTH:0] waddr_bin, raddr_bin;
reg [ADDR_WIDTH:0] wptr, rptr;

wire wen = wrstn && winc && !wfull;
wire ren = rrstn && rinc && !rempty;

function automatic [ADDR_WIDTH:0] advance_pointer(
    input [ADDR_WIDTH:0] pointer
);
    if (pointer[ADDR_WIDTH-1:0] == LAST_ADDR)
        advance_pointer = {~pointer[ADDR_WIDTH], {ADDR_WIDTH{1'b0}}};
    else
        advance_pointer = pointer + 1'b1;
endfunction

function automatic [ADDR_WIDTH:0] gray_pointer(
    input [ADDR_WIDTH:0] pointer
);
    reg [ADDR_WIDTH-1:0] addr;
    begin
        // Reflect the address sequence in the second lap. At either wrap,
        // the reflected address holds and only the lap bit changes.
        addr = pointer[ADDR_WIDTH-1:0];
        if (pointer[ADDR_WIDTH])
            addr = LAST_ADDR - addr;
        gray_pointer = {pointer[ADDR_WIDTH], addr ^ (addr >> 1)};
    end
endfunction

wire [ADDR_WIDTH:0] waddr_next = advance_pointer(waddr_bin);
wire [ADDR_WIDTH:0] raddr_next = advance_pointer(raddr_bin);

always @(posedge wclk or negedge wrstn) begin
    if (!wrstn) begin
        waddr_bin <= '0;
        wptr <= '0;
    end else if (wen) begin
        waddr_bin <= waddr_next;
        wptr <= gray_pointer(waddr_next);
    end
end

always @(posedge rclk or negedge rrstn) begin
    if (!rrstn) begin
        raddr_bin <= '0;
        rptr <= '0;
    end else if (ren) begin
        raddr_bin <= raddr_next;
        rptr <= gray_pointer(raddr_next);
    end
end

(* ASYNC_REG = "TRUE" *) reg [ADDR_WIDTH:0] wptr_buff, wptr_syn;
(* ASYNC_REG = "TRUE" *) reg [ADDR_WIDTH:0] rptr_buff, rptr_syn;

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

// Full is the same RAM address as the synchronized read pointer one lap away.
assign wfull = (gray_pointer({~waddr_bin[ADDR_WIDTH],
                              waddr_bin[ADDR_WIDTH-1:0]}) == rptr_syn);
assign rempty = (rptr == wptr_syn);

// Match the supplied RAM's address ports, including its fixed address at DEPTH=1.
wire [$clog2(DEPTH)-1:0] waddr = (DEPTH == 1) ? '0 : waddr_bin[ADDR_WIDTH-1:0];
wire [$clog2(DEPTH)-1:0] raddr = (DEPTH == 1) ? '0 : raddr_bin[ADDR_WIDTH-1:0];

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
