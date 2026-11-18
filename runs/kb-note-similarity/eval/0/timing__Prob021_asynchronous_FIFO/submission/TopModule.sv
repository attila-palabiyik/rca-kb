module TopModule #(
    parameter WIDTH = 8,
    parameter DEPTH = 16
)(
    input wclk,
    input rclk,
    input wrstn,
    input rrstn,
    input winc,
    input rinc,
    input [WIDTH-1:0] wdata,
    output wire wfull,
    output wire rempty,
    output wire [WIDTH-1:0] rdata
);

parameter ADDR_WIDTH = $clog2(DEPTH);
localparam RAM_ADDR_WIDTH = $clog2(DEPTH);
localparam [ADDR_WIDTH:0] FIFO_DEPTH = (ADDR_WIDTH + 1)'(DEPTH);

reg [ADDR_WIDTH:0] waddr_bin;
reg [ADDR_WIDTH:0] raddr_bin;
reg [ADDR_WIDTH:0] wptr;
reg [ADDR_WIDTH:0] rptr;

(* ASYNC_REG = "TRUE" *) reg [ADDR_WIDTH:0] rptr_buff, rptr_syn;
(* ASYNC_REG = "TRUE" *) reg [ADDR_WIDTH:0] wptr_buff, wptr_syn;

wire wen = wrstn && winc && !wfull;
wire ren = rrstn && rinc && !rempty;
wire [ADDR_WIDTH:0] waddr_next = waddr_bin + 1'b1;
wire [ADDR_WIDTH:0] raddr_next = raddr_bin + 1'b1;

function automatic [ADDR_WIDTH:0] binary_to_gray(input [ADDR_WIDTH:0] count);
    binary_to_gray = count ^ (count >> 1);
endfunction

// Register the Gray pointer on the same edge as its accepted transfer.
always @(posedge wclk or negedge wrstn) begin
    if (!wrstn) begin
        waddr_bin <= '0;
        wptr <= '0;
    end else if (wen) begin
        waddr_bin <= waddr_next;
        wptr <= binary_to_gray(waddr_next);
    end
end

always @(posedge rclk or negedge rrstn) begin
    if (!rrstn) begin
        raddr_bin <= '0;
        rptr <= '0;
    end else if (ren) begin
        raddr_bin <= raddr_next;
        rptr <= binary_to_gray(raddr_next);
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

// Full when the synchronized read count trails the write count by DEPTH.
assign wfull = (rptr_syn == binary_to_gray(waddr_bin - FIFO_DEPTH));
assign rempty = (rptr == wptr_syn);

wire [RAM_ADDR_WIDTH-1:0] waddr;
wire [RAM_ADDR_WIDTH-1:0] raddr;

generate
    if (DEPTH == 1) begin : single_entry
        assign waddr = '0;
        assign raddr = '0;
    end else if ((DEPTH & (DEPTH - 1)) == 0) begin : power_of_two
        assign waddr = waddr_bin[RAM_ADDR_WIDTH-1:0];
        assign raddr = raddr_bin[RAM_ADDR_WIDTH-1:0];
    end else begin : exact_depth
        // The RAM addresses wrap at DEPTH. The Gray counters wrap at a power of two.
        localparam [RAM_ADDR_WIDTH-1:0] LAST_ADDR = RAM_ADDR_WIDTH'(DEPTH - 1);
        reg [RAM_ADDR_WIDTH-1:0] write_address;
        reg [RAM_ADDR_WIDTH-1:0] read_address;

        always @(posedge wclk or negedge wrstn) begin
            if (!wrstn)
                write_address <= '0;
            else if (wen)
                write_address <= (write_address == LAST_ADDR) ? '0 : write_address + 1'b1;
        end

        always @(posedge rclk or negedge rrstn) begin
            if (!rrstn)
                read_address <= '0;
            else if (ren)
                read_address <= (read_address == LAST_ADDR) ? '0 : read_address + 1'b1;
        end

        assign waddr = write_address;
        assign raddr = read_address;
    end
endgenerate

dual_port_RAM #(.DEPTH(DEPTH), .WIDTH(WIDTH)) dual_port_RAM (
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
