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

reg [ADDR_WIDTH-1:0] write_addr, read_addr;
reg write_wrap, read_wrap;

assign wfull  = (write_addr == read_addr) && (write_wrap != read_wrap);
assign rempty = (write_addr == read_addr) && (write_wrap == read_wrap);

wire wenc = rst_n && winc && !wfull;
wire renc = rst_n && rinc && !rempty;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        write_addr <= '0;
        write_wrap <= 1'b0;
        read_addr <= '0;
        read_wrap <= 1'b0;
    end else begin
        if (wenc) begin
            if (write_addr == LAST_ADDR) begin
                write_addr <= '0;
                write_wrap <= ~write_wrap;
            end else begin
                write_addr <= write_addr + 1'b1;
            end
        end

        if (renc) begin
            if (read_addr == LAST_ADDR) begin
                read_addr <= '0;
                read_wrap <= ~read_wrap;
            end else begin
                read_addr <= read_addr + 1'b1;
            end
        end
    end
end

// Match the supplied RAM's port ranges, including its [-1:0] range at depth 1.
wire [$clog2(DEPTH)-1:0] ram_write_addr = write_addr;
wire [$clog2(DEPTH)-1:0] ram_read_addr = read_addr;

dual_port_RAM #(.DEPTH(DEPTH), .WIDTH(WIDTH)) u_ram (
    .wclk  (clk),
    .wenc  (wenc),
    .waddr (ram_write_addr),
    .wdata (wdata),
    .rclk  (clk),
    .renc  (renc),
    .raddr (ram_read_addr),
    .rdata (rdata)
);

endmodule
