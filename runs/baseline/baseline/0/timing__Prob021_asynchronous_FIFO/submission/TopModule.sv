module TopModule #(
    parameter WIDTH = 8,
    parameter DEPTH = 16
)(
    input                   wclk,
    input                   rclk,
    input                   wrstn,
    input                   rrstn,
    input                   winc,
    input                   rinc,
    input      [WIDTH-1:0]  wdata,

    output reg              wfull,
    output reg              rempty,
    output wire [WIDTH-1:0] rdata
);

parameter ADDR_WIDTH = $clog2(DEPTH);
localparam PTR_WIDTH = ADDR_WIDTH + 1;
localparam RAM_ADDR_WIDTH = $clog2(DEPTH);

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
        wbin  <= '0;
        wgray <= '0;
        wfull <= 1'b0;
    end else begin
        wbin  <= wbin_next;
        wgray <= wgray_next;
        wfull <= wfull_next;
    end
end

always @(posedge rclk or negedge rrstn) begin
    if (!rrstn) begin
        rbin   <= '0;
        rgray  <= '0;
        rempty <= 1'b1;
    end else begin
        rbin   <= rbin_next;
        rgray  <= rgray_next;
        rempty <= (rgray_next == wgray_sync);
    end
end

always @(posedge wclk or negedge wrstn) begin
    if (!wrstn) begin
        rgray_meta <= '0;
        rgray_sync <= '0;
    end else begin
        rgray_meta <= rgray;
        rgray_sync <= rgray_meta;
    end
end

always @(posedge rclk or negedge rrstn) begin
    if (!rrstn) begin
        wgray_meta <= '0;
        wgray_sync <= '0;
    end else begin
        wgray_meta <= wgray;
        wgray_sync <= wgray_meta;
    end
end

wire [RAM_ADDR_WIDTH-1:0] waddr, raddr;
generate
    if (DEPTH == 1) begin : single_entry
        assign waddr = '0;
        assign raddr = '0;
        assign wfull_next = (wgray_next != rgray_sync);
    end else if ((DEPTH & (DEPTH - 1)) == 0) begin : power_of_two
        // A one-buffer separation flips the top two Gray bits.
        localparam [PTR_WIDTH-1:0] FULL_MASK = {2'b11, {(PTR_WIDTH-2){1'b0}}};
        assign wfull_next = (wgray_next == (rgray_sync ^ FULL_MASK));
        assign waddr = wbin[RAM_ADDR_WIDTH-1:0];
        assign raddr = rbin[RAM_ADDR_WIDTH-1:0];
    end else begin : non_power_of_two
        localparam [PTR_WIDTH-1:0] CAPACITY = PTR_WIDTH'(DEPTH);
        localparam [RAM_ADDR_WIDTH-1:0] LAST_ADDR = RAM_ADDR_WIDTH'(DEPTH - 1);
        wire [PTR_WIDTH-1:0] rbin_sync;
        wire [PTR_WIDTH-1:0] used_next = wbin_next - rbin_sync;
        reg [RAM_ADDR_WIDTH-1:0] write_addr, read_addr;

        // Keep the crossing counters on a power-of-two Gray cycle.
        // The local RAM addresses wrap at the actual capacity.
        for (genvar bit_index = 0; bit_index < PTR_WIDTH; bit_index = bit_index + 1) begin : decode_gray
            assign rbin_sync[bit_index] = ^rgray_sync[PTR_WIDTH-1:bit_index];
        end
        assign wfull_next = (used_next == CAPACITY);
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
