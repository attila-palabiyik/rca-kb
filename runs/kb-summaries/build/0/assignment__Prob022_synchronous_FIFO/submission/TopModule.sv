module TopModule #(
    parameter WIDTH = 8,
    parameter DEPTH = 16
)(
    input                   clk,
    input                   rst_n,
    input                   winc,
    input                   rinc,
    input       [WIDTH-1:0] wdata,
    output                  wfull,
    output                  rempty,
    output wire [WIDTH-1:0] rdata
);

localparam ADDR_WIDTH = (DEPTH > 1) ? $clog2(DEPTH) : 1;
localparam [ADDR_WIDTH-1:0] LAST_ADDR = ADDR_WIDTH'(DEPTH - 1);

reg [ADDR_WIDTH:0] write_ptr;
reg [ADDR_WIDTH:0] read_ptr;

wire [ADDR_WIDTH-1:0] waddr = write_ptr[ADDR_WIDTH-1:0];
wire [ADDR_WIDTH-1:0] raddr = read_ptr[ADDR_WIDTH-1:0];
wire same_address = (waddr == raddr);
wire same_wrap = (write_ptr[ADDR_WIDTH] == read_ptr[ADDR_WIDTH]);

assign rempty = same_address && same_wrap;
assign wfull = same_address && !same_wrap;

wire wenc = rst_n && winc && !wfull;
wire renc = rst_n && rinc && !rempty;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        write_ptr <= '0;
    else if (wenc) begin
        if (waddr == LAST_ADDR)
            write_ptr <= {~write_ptr[ADDR_WIDTH], {ADDR_WIDTH{1'b0}}};
        else
            write_ptr <= write_ptr + 1'b1;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        read_ptr <= '0;
    else if (renc) begin
        if (raddr == LAST_ADDR)
            read_ptr <= {~read_ptr[ADDR_WIDTH], {ADDR_WIDTH{1'b0}}};
        else
            read_ptr <= read_ptr + 1'b1;
    end
end

dual_port_RAM #(.DEPTH(DEPTH), .WIDTH(WIDTH)) u_ram (
    .wclk  (clk),
    .wenc  (wenc),
    .waddr (waddr),
    .wdata (wdata),
    .rclk  (clk),
    .renc  (renc),
    .raddr (raddr),
    .rdata (rdata)
);

endmodule

module dual_port_RAM #(
    parameter DEPTH = 16,
    parameter WIDTH = 8
)(
    input                                           wclk,
    input                                           wenc,
    input  [(DEPTH > 1 ? $clog2(DEPTH) : 1)-1:0]     waddr,
    input  [WIDTH-1:0]                              wdata,
    input                                           rclk,
    input                                           renc,
    input  [(DEPTH > 1 ? $clog2(DEPTH) : 1)-1:0]     raddr,
    output reg [WIDTH-1:0]                          rdata
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
