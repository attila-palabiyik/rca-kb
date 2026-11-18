module TopModule #(
    parameter WIDTH = 8,
    parameter DEPTH = 16
)(
    input  wire             clk,
    input  wire             rst_n,
    input  wire             winc,
    input  wire             rinc,
    input  wire [WIDTH-1:0] wdata,
    output wire             wfull,
    output wire             rempty,
    output wire [WIDTH-1:0] rdata
);

localparam ADDR_WIDTH = (DEPTH > 1) ? $clog2(DEPTH) : 1;
localparam [ADDR_WIDTH-1:0] LAST_ADDR = ADDR_WIDTH'(DEPTH - 1);

reg [ADDR_WIDTH-1:0] waddr;
reg [ADDR_WIDTH-1:0] raddr;
reg wwrap;
reg rwrap;

wire same_addr = (waddr == raddr);
assign wfull = same_addr && (wwrap != rwrap);
assign rempty = same_addr && (wwrap == rwrap);

wire wenc = rst_n && winc && !wfull;
wire renc = rst_n && rinc && !rempty;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        waddr <= 0;
        raddr <= 0;
        wwrap <= 0;
        rwrap <= 0;
    end else begin
        if (wenc) begin
            if (waddr == LAST_ADDR) begin
                waddr <= 0;
                wwrap <= ~wwrap;
            end else begin
                waddr <= waddr + 1'b1;
            end
        end

        if (renc) begin
            if (raddr == LAST_ADDR) begin
                raddr <= 0;
                rwrap <= ~rwrap;
            end else begin
                raddr <= raddr + 1'b1;
            end
        end
    end
end

// Match the supplied RAM's address range, including its [-1:0] range at depth 1.
wire [$clog2(DEPTH)-1:0] ram_waddr = waddr;
wire [$clog2(DEPTH)-1:0] ram_raddr = raddr;

dual_port_RAM #(.DEPTH(DEPTH), .WIDTH(WIDTH)) u_ram (
    .wclk  (clk),
    .wenc  (wenc),
    .waddr (ram_waddr),
    .wdata (wdata),
    .rclk  (clk),
    .renc  (renc),
    .raddr (ram_raddr),
    .rdata (rdata)
);

endmodule
