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
localparam INDEX_WIDTH = (ADDR_WIDTH > 0) ? ADDR_WIDTH : 1;
localparam [INDEX_WIDTH-1:0] LAST_ADDR = INDEX_WIDTH'(DEPTH - 1);

reg [INDEX_WIDTH-1:0] waddr, raddr;
reg wphase, rphase;
reg [INDEX_WIDTH:0] wptr, rptr;
reg [INDEX_WIDTH:0] wptr_full;

(* ASYNC_REG = "TRUE" *) reg [INDEX_WIDTH:0] rptr_buff, rptr_syn;
(* ASYNC_REG = "TRUE" *) reg [INDEX_WIDTH:0] wptr_buff, wptr_syn;

wire wen = wrstn && winc && !wfull;
wire ren = rrstn && rinc && !rempty;
wire wwrap = waddr == LAST_ADDR;
wire rwrap = raddr == LAST_ADDR;
wire [INDEX_WIDTH-1:0] waddr_next = wwrap ? '0 : waddr + 1'b1;
wire [INDEX_WIDTH-1:0] raddr_next = rwrap ? '0 : raddr + 1'b1;
wire wphase_next = wphase ^ wwrap;
wire rphase_next = rphase ^ rwrap;

// Traverse the Gray sequence forward on the first lap and backward on
// the second, so wrapping at any depth changes only the phase bit.
function automatic [INDEX_WIDTH:0] gray_pointer(
    input phase,
    input [INDEX_WIDTH-1:0] addr
);
    reg [INDEX_WIDTH-1:0] index;
    begin
        index = phase ? LAST_ADDR - addr : addr;
        gray_pointer = {phase, index ^ (index >> 1)};
    end
endfunction

always @(posedge wclk or negedge wrstn) begin
    if (!wrstn) begin
        waddr <= '0;
        wphase <= 1'b0;
        wptr <= '0;
        wptr_full <= gray_pointer(1'b1, '0);
    end else if (wen) begin
        waddr <= waddr_next;
        wphase <= wphase_next;
        wptr <= gray_pointer(wphase_next, waddr_next);
        wptr_full <= gray_pointer(!wphase_next, waddr_next);
    end
end

always @(posedge rclk or negedge rrstn) begin
    if (!rrstn) begin
        raddr <= '0;
        rphase <= 1'b0;
        rptr <= '0;
    end else if (ren) begin
        raddr <= raddr_next;
        rphase <= rphase_next;
        rptr <= gray_pointer(rphase_next, raddr_next);
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

// Full means the read pointer is at the write address on the opposite lap.
assign wfull = wptr_full == rptr_syn;
assign rempty = rptr == wptr_syn;

// Match the supplied RAM's port widths, including its depth-one declaration.
wire [ADDR_WIDTH-1:0] ram_waddr = waddr;
wire [ADDR_WIDTH-1:0] ram_raddr = raddr;

dual_port_RAM #(.DEPTH(DEPTH), .WIDTH(WIDTH)) dual_port_RAM (
    .wclk(wclk),
    .wenc(wen),
    .waddr(ram_waddr),
    .wdata(wdata),
    .rclk(rclk),
    .renc(ren),
    .raddr(ram_raddr),
    .rdata(rdata)
);

endmodule
