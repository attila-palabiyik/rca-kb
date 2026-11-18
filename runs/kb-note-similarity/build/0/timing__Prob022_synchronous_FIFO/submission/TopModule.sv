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

    // The supplied RAM declares a two-bit [-1:0] address when DEPTH is 1.
    localparam ADDR_WIDTH = (DEPTH == 1) ? 2 : $clog2(DEPTH);
    localparam [ADDR_WIDTH-1:0] LAST_ADDR = ADDR_WIDTH'(DEPTH - 1);

    reg [ADDR_WIDTH-1:0] waddr, raddr;
    reg wwrap, rwrap;

    wire same_addr = (waddr == raddr);
    assign wfull = same_addr && (wwrap != rwrap);
    assign rempty = same_addr && (wwrap == rwrap);

    wire wenc = rst_n && winc && !wfull;
    wire renc = rst_n && rinc && !rempty;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            waddr <= 0;
            wwrap <= 0;
        end else if (wenc) begin
            if (waddr == LAST_ADDR) begin
                waddr <= 0;
                wwrap <= ~wwrap;
            end else begin
                waddr <= waddr + 1'b1;
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            raddr <= 0;
            rwrap <= 0;
        end else if (renc) begin
            if (raddr == LAST_ADDR) begin
                raddr <= 0;
                rwrap <= ~rwrap;
            end else begin
                raddr <= raddr + 1'b1;
            end
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
