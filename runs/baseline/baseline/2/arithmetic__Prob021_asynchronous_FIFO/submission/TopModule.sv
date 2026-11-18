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
    output reg wfull,
    output reg rempty,
    output wire [WIDTH-1:0] rdata
);

parameter ADDR_WIDTH = $clog2(DEPTH);
localparam RAM_ADDR_WIDTH = DEPTH > 1 ? $clog2(DEPTH) : 1;
localparam [ADDR_WIDTH:0] FIFO_DEPTH = DEPTH;

reg [ADDR_WIDTH:0] waddr_bin, raddr_bin;
reg [ADDR_WIDTH:0] wptr, rptr;
(* ASYNC_REG = "TRUE" *) reg [ADDR_WIDTH:0] rptr_buff, rptr_syn;
(* ASYNC_REG = "TRUE" *) reg [ADDR_WIDTH:0] wptr_buff, wptr_syn;

wire wen = wrstn && winc && !wfull;
wire ren = rrstn && rinc && !rempty;
wire [ADDR_WIDTH:0] waddr_bin_next = waddr_bin + wen;
wire [ADDR_WIDTH:0] raddr_bin_next = raddr_bin + ren;
wire [ADDR_WIDTH:0] wptr_next = waddr_bin_next ^ (waddr_bin_next >> 1);
wire [ADDR_WIDTH:0] rptr_next = raddr_bin_next ^ (raddr_bin_next >> 1);
wire [RAM_ADDR_WIDTH-1:0] waddr, raddr;
wire wfull_next;

function automatic [ADDR_WIDTH:0] gray_to_binary(input [ADDR_WIDTH:0] gray);
    integer bit_index;
    begin
        gray_to_binary[ADDR_WIDTH] = gray[ADDR_WIDTH];
        for (bit_index = ADDR_WIDTH-1; bit_index >= 0; bit_index = bit_index-1)
            gray_to_binary[bit_index] = gray_to_binary[bit_index+1] ^ gray[bit_index];
    end
endfunction

always @(posedge wclk or negedge wrstn) begin
    if (!wrstn) begin
        waddr_bin <= '0;
        wptr <= '0;
        wfull <= 1'b0;
    end else begin
        waddr_bin <= waddr_bin_next;
        wptr <= wptr_next;
        wfull <= wfull_next;
    end
end

always @(posedge rclk or negedge rrstn) begin
    if (!rrstn) begin
        raddr_bin <= '0;
        rptr <= '0;
        rempty <= 1'b1;
    end else begin
        raddr_bin <= raddr_bin_next;
        rptr <= rptr_next;
        rempty <= (rptr_next == wptr_syn);
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

generate
    if ((DEPTH & (DEPTH-1)) == 0) begin : power_of_two
        // The wrap bit and the next lower bit (if present) flip in Gray code.
        localparam [ADDR_WIDTH:0] FULL_MASK = FIFO_DEPTH | (FIFO_DEPTH >> 1);
        assign wfull_next = (wptr_next == (rptr_syn ^ FULL_MASK));
        assign waddr = DEPTH == 1 ? '0 : waddr_bin[RAM_ADDR_WIDTH-1:0];
        assign raddr = DEPTH == 1 ? '0 : raddr_bin[RAM_ADDR_WIDTH-1:0];
    end else begin : other_depth
        localparam [RAM_ADDR_WIDTH-1:0] LAST_ADDR = DEPTH-1;
        reg [RAM_ADDR_WIDTH-1:0] write_addr, read_addr;

        // Keep the CDC counts on a power-of-two cycle so every Gray step
        // changes one bit. Wrap the local RAM addresses at the actual depth.
        assign wfull_next = (waddr_bin_next == gray_to_binary(rptr_syn) + FIFO_DEPTH);
        assign waddr = write_addr;
        assign raddr = read_addr;

        always @(posedge wclk or negedge wrstn) begin
            if (!wrstn)
                write_addr <= '0;
            else if (wen)
                write_addr <= (write_addr == LAST_ADDR) ? '0 : write_addr + 1'b1;
        end

        always @(posedge rclk or negedge rrstn) begin
            if (!rrstn)
                read_addr <= '0;
            else if (ren)
                read_addr <= (read_addr == LAST_ADDR) ? '0 : read_addr + 1'b1;
        end
    end
endgenerate

dual_port_RAM #(.DEPTH(DEPTH), .WIDTH(WIDTH)) storage (
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

module dual_port_RAM #(
    parameter DEPTH = 16,
    parameter WIDTH = 8
)(
    input wire wclk,
    input wire wenc,
    input wire [(DEPTH > 1 ? $clog2(DEPTH) : 1)-1:0] waddr,
    input wire [WIDTH-1:0] wdata,
    input wire rclk,
    input wire renc,
    input wire [(DEPTH > 1 ? $clog2(DEPTH) : 1)-1:0] raddr,
    output reg [WIDTH-1:0] rdata
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
