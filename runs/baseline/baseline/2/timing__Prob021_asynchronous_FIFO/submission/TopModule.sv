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

    output reg              wfull,
    output reg              rempty,
    output wire [WIDTH-1:0] rdata
);

parameter ADDR_WIDTH = $clog2(DEPTH);

localparam RAM_ADDR_WIDTH = $clog2(DEPTH);
localparam PTR_WIDTH = ADDR_WIDTH + 1;
localparam [PTR_WIDTH-1:0] CAPACITY = DEPTH;

reg [PTR_WIDTH-1:0] wbin, rbin;
reg [PTR_WIDTH-1:0] wgray, rgray;
(* ASYNC_REG = "TRUE" *) reg [PTR_WIDTH-1:0] rgray_meta, rgray_sync;
(* ASYNC_REG = "TRUE" *) reg [PTR_WIDTH-1:0] wgray_meta, wgray_sync;

wire wen = wrstn && winc && !wfull;
wire ren = rrstn && rinc && !rempty;
wire [PTR_WIDTH-1:0] wbin_next = wbin + wen;
wire [PTR_WIDTH-1:0] rbin_next = rbin + ren;
wire [PTR_WIDTH-1:0] wgray_next = wbin_next ^ (wbin_next >> 1);
wire [PTR_WIDTH-1:0] rgray_next = rbin_next ^ (rbin_next >> 1);
wire wfull_next;

always @(posedge wclk or negedge wrstn) begin
    if (!wrstn) begin
        wbin       <= 0;
        wgray      <= 0;
        rgray_meta <= 0;
        rgray_sync <= 0;
        wfull      <= 1'b0;
    end else begin
        wbin       <= wbin_next;
        wgray      <= wgray_next;
        rgray_meta <= rgray;
        rgray_sync <= rgray_meta;
        wfull      <= wfull_next;
    end
end

always @(posedge rclk or negedge rrstn) begin
    if (!rrstn) begin
        rbin       <= 0;
        rgray      <= 0;
        wgray_meta <= 0;
        wgray_sync <= 0;
        rempty     <= 1'b1;
    end else begin
        rbin       <= rbin_next;
        rgray      <= rgray_next;
        wgray_meta <= wgray;
        wgray_sync <= wgray_meta;
        rempty     <= (rgray_next == wgray_sync);
    end
end

wire [RAM_ADDR_WIDTH-1:0] waddr, raddr;

generate
    if (DEPTH == 1) begin : single_entry
        assign waddr = 0;
        assign raddr = 0;
    end else if ((DEPTH & (DEPTH - 1)) == 0) begin : power_of_two_addresses
        assign waddr = wbin[RAM_ADDR_WIDTH-1:0];
        assign raddr = rbin[RAM_ADDR_WIDTH-1:0];
    end else begin : wrapped_addresses
        // RAM addresses wrap at DEPTH while the CDC counters wrap at a power of two.
        localparam [RAM_ADDR_WIDTH-1:0] LAST_ADDR = DEPTH - 1;
        reg [RAM_ADDR_WIDTH-1:0] write_addr, read_addr;

        always @(posedge wclk or negedge wrstn) begin
            if (!wrstn)
                write_addr <= 0;
            else if (wen)
                write_addr <= (write_addr == LAST_ADDR) ? 0 : write_addr + 1'b1;
        end

        always @(posedge rclk or negedge rrstn) begin
            if (!rrstn)
                read_addr <= 0;
            else if (ren)
                read_addr <= (read_addr == LAST_ADDR) ? 0 : read_addr + 1'b1;
        end

        assign waddr = write_addr;
        assign raddr = read_addr;
    end

    if ((DEPTH > 1) && (ADDR_WIDTH == RAM_ADDR_WIDTH) &&
        ((DEPTH & (DEPTH - 1)) == 0)) begin : gray_full
        // A half-cycle offset in the binary counter flips the top two Gray bits.
        localparam [PTR_WIDTH-1:0] FULL_MASK = 2'b11 << (PTR_WIDTH - 2);
        assign wfull_next = (wgray_next == (rgray_sync ^ FULL_MASK));
    end else begin : distance_full
        wire [PTR_WIDTH-1:0] synced_read_bin;
        wire [PTR_WIDTH-1:0] used_next = wbin_next - synced_read_bin;

        for (genvar bit_index = 0; bit_index < PTR_WIDTH; bit_index = bit_index + 1) begin : decode
            assign synced_read_bin[bit_index] = ^rgray_sync[PTR_WIDTH-1:bit_index];
        end

        assign wfull_next = (used_next == CAPACITY);
    end
endgenerate

dual_port_RAM #(
    .DEPTH(DEPTH),
    .WIDTH(WIDTH)
) fifo_ram (
    .wclk (wclk),
    .wenc (wen),
    .waddr(waddr),
    .wdata(wdata),
    .rclk (rclk),
    .renc (ren),
    .raddr(raddr),
    .rdata(rdata)
);

endmodule
