module TopModule #(
    parameter WIDTH = 8,
    parameter DEPTH = 16,
    parameter ADDR_WIDTH = (DEPTH > 1) ? $clog2(DEPTH) : 1
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

    localparam [ADDR_WIDTH:0] CAPACITY = DEPTH;

    function automatic [ADDR_WIDTH:0] to_gray(input [ADDR_WIDTH:0] binary);
        to_gray = binary ^ (binary >> 1);
    endfunction

    wire wen = wrstn && winc && !wfull;
    wire ren = rrstn && rinc && !rempty;

    reg [ADDR_WIDTH:0] wcount, rcount;
    wire [ADDR_WIDTH:0] wcount_next = wcount + wen;
    wire [ADDR_WIDTH:0] rcount_next = rcount + ren;
    reg [ADDR_WIDTH:0] wptr, rptr;
    reg [ADDR_WIDTH:0] full_rptr;

    (* async_reg = "true" *) reg [ADDR_WIDTH:0] rptr_buff, rptr_syn;
    (* async_reg = "true" *) reg [ADDR_WIDTH:0] wptr_buff, wptr_syn;

    always @(posedge wclk or negedge wrstn) begin
        if (!wrstn) begin
            wcount <= '0;
            wptr <= '0;
            full_rptr <= to_gray(-CAPACITY);
            rptr_buff <= '0;
            rptr_syn <= '0;
        end else begin
            wcount <= wcount_next;
            wptr <= to_gray(wcount_next);
            // Full when the synchronized read count is DEPTH writes behind.
            full_rptr <= to_gray(wcount_next - CAPACITY);
            rptr_buff <= rptr;
            rptr_syn <= rptr_buff;
        end
    end

    always @(posedge rclk or negedge rrstn) begin
        if (!rrstn) begin
            rcount <= '0;
            rptr <= '0;
            wptr_buff <= '0;
            wptr_syn <= '0;
        end else begin
            rcount <= rcount_next;
            rptr <= to_gray(rcount_next);
            wptr_buff <= wptr;
            wptr_syn <= wptr_buff;
        end
    end

    assign wfull = (full_rptr == rptr_syn);
    assign rempty = (rptr == wptr_syn);

    wire [ADDR_WIDTH-1:0] waddr, raddr;
    generate
        if (DEPTH == 2**ADDR_WIDTH) begin : power_of_two_depth
            assign waddr = wcount[ADDR_WIDTH-1:0];
            assign raddr = rcount[ADDR_WIDTH-1:0];
        end else begin : other_depth
            // Keep the Gray counters on their power-of-two cycle while the
            // RAM addresses wrap at the actual depth.
            localparam [ADDR_WIDTH-1:0] LAST_ADDR = DEPTH - 1;
            reg [ADDR_WIDTH-1:0] windex, rindex;

            always @(posedge wclk or negedge wrstn) begin
                if (!wrstn)
                    windex <= '0;
                else if (wen)
                    windex <= (windex == LAST_ADDR) ? '0 : windex + 1'b1;
            end

            always @(posedge rclk or negedge rrstn) begin
                if (!rrstn)
                    rindex <= '0;
                else if (ren)
                    rindex <= (rindex == LAST_ADDR) ? '0 : rindex + 1'b1;
            end

            assign waddr = windex;
            assign raddr = rindex;
        end
    endgenerate

    dual_port_RAM #(.DEPTH(DEPTH), .WIDTH(WIDTH)) storage (
        .wclk  (wclk),
        .wenc  (wen),
        .waddr (waddr),
        .wdata (wdata),
        .rclk  (rclk),
        .renc  (ren),
        .raddr (raddr),
        .rdata (rdata)
    );

endmodule

module dual_port_RAM #(
    parameter DEPTH = 16,
    parameter WIDTH = 8,
    localparam ADDR_WIDTH = (DEPTH > 1) ? $clog2(DEPTH) : 1
)(
    input  wire                  wclk,
    input  wire                  wenc,
    input  wire [ADDR_WIDTH-1:0] waddr,
    input  wire [WIDTH-1:0]      wdata,
    input  wire                  rclk,
    input  wire                  renc,
    input  wire [ADDR_WIDTH-1:0] raddr,
    output reg  [WIDTH-1:0]      rdata
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
