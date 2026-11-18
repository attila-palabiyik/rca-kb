module TopModule #(
    parameter WIDTH = 8,
    parameter DEPTH = 16
)(
    input clk,
    input rst_n,
    input winc,
    input rinc,
    input [WIDTH-1:0] wdata,
    output wfull,
    output rempty,
    output wire [WIDTH-1:0] rdata
);

localparam ADDR_WIDTH = (DEPTH > 1) ? $clog2(DEPTH) : 1;
localparam [ADDR_WIDTH-1:0] LAST_ADDR = ADDR_WIDTH'(DEPTH - 1);

reg [ADDR_WIDTH:0] write_ptr;
reg [ADDR_WIDTH:0] read_ptr;

wire [ADDR_WIDTH-1:0] write_addr = write_ptr[ADDR_WIDTH-1:0];
wire [ADDR_WIDTH-1:0] read_addr = read_ptr[ADDR_WIDTH-1:0];

assign rempty = (write_ptr == read_ptr);
assign wfull = (write_addr == read_addr) &&
               (write_ptr[ADDR_WIDTH] != read_ptr[ADDR_WIDTH]);

wire wenc = rst_n && winc && !wfull;
wire renc = rst_n && rinc && !rempty;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        write_ptr <= 0;
        read_ptr <= 0;
    end else begin
        if (wenc) begin
            if (write_addr == LAST_ADDR)
                write_ptr <= {~write_ptr[ADDR_WIDTH], {ADDR_WIDTH{1'b0}}};
            else
                write_ptr <= write_ptr + 1'b1;
        end

        if (renc) begin
            if (read_addr == LAST_ADDR)
                read_ptr <= {~read_ptr[ADDR_WIDTH], {ADDR_WIDTH{1'b0}}};
            else
                read_ptr <= read_ptr + 1'b1;
        end
    end
end

// Match the supplied RAM's address ports, including its [-1:0] range at DEPTH=1.
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
