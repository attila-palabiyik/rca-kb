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
    output wire             wfull,
    output wire             rempty,
    output wire [WIDTH-1:0] rdata
);

parameter ADDR_WIDTH = $clog2(DEPTH);
localparam PTR_WIDTH = ADDR_WIDTH + 1;

wire wen = wrstn && winc && !wfull;
wire ren = rrstn && rinc && !rempty;

reg [PTR_WIDTH-1:0] wbin, rbin;
reg [PTR_WIDTH-1:0] wgray, rgray;
wire [PTR_WIDTH-1:0] wbin_next = wbin + 1'b1;
wire [PTR_WIDTH-1:0] rbin_next = rbin + 1'b1;

(* ASYNC_REG = "TRUE" *) reg [PTR_WIDTH-1:0] rgray_meta, rgray_sync;
(* ASYNC_REG = "TRUE" *) reg [PTR_WIDTH-1:0] wgray_meta, wgray_sync;

always @(posedge wclk or negedge wrstn) begin
    if (!wrstn) begin
        wbin       <= '0;
        wgray      <= '0;
        rgray_meta <= '0;
        rgray_sync <= '0;
    end else begin
        rgray_meta <= rgray;
        rgray_sync <= rgray_meta;
        if (wen) begin
            wbin  <= wbin_next;
            wgray <= wbin_next ^ (wbin_next >> 1);
        end
    end
end

always @(posedge rclk or negedge rrstn) begin
    if (!rrstn) begin
        rbin       <= '0;
        rgray      <= '0;
        wgray_meta <= '0;
        wgray_sync <= '0;
    end else begin
        wgray_meta <= wgray;
        wgray_sync <= wgray_meta;
        if (ren) begin
            rbin  <= rbin_next;
            rgray <= rbin_next ^ (rbin_next >> 1);
        end
    end
end

function automatic [PTR_WIDTH-1:0] gray_to_binary(input [PTR_WIDTH-1:0] gray);
    gray_to_binary[PTR_WIDTH-1] = gray[PTR_WIDTH-1];
    for (integer bit_index = PTR_WIDTH-2; bit_index >= 0; bit_index = bit_index-1)
        gray_to_binary[bit_index] = gray_to_binary[bit_index+1] ^ gray[bit_index];
endfunction

// Modular subtraction gives the number of writes not yet seen as read.
wire [PTR_WIDTH-1:0] write_used = wbin - gray_to_binary(rgray_sync);
assign wfull  = (write_used == PTR_WIDTH'(DEPTH));
assign rempty = (rgray == wgray_sync);

wire [ADDR_WIDTH-1:0] waddr, raddr;
generate
    if (DEPTH == 1) begin : single_slot
        assign waddr = '0;
        assign raddr = '0;
    end else if ((DEPTH & (DEPTH - 1)) == 0) begin : power_of_two
        assign waddr = wbin[ADDR_WIDTH-1:0];
        assign raddr = rbin[ADDR_WIDTH-1:0];
    end else begin : explicit_address_wrap
        // RAM addresses wrap at DEPTH while the CDC counters keep a full Gray cycle.
        localparam [ADDR_WIDTH-1:0] LAST_ADDR = ADDR_WIDTH'(DEPTH - 1);
        reg [ADDR_WIDTH-1:0] write_addr, read_addr;

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

        assign waddr = write_addr;
        assign raddr = read_addr;
    end
endgenerate

dual_port_RAM #(
    .DEPTH(DEPTH),
    .WIDTH(WIDTH)
) dual_port_RAM (
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
