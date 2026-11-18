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
    localparam [ADDR_WIDTH-1:0] LAST_ADDR = DEPTH - 1;

    reg [ADDR_WIDTH:0] wptr;
    reg [ADDR_WIDTH:0] rptr;
    wire [ADDR_WIDTH-1:0] waddr = wptr[ADDR_WIDTH-1:0];
    wire [ADDR_WIDTH-1:0] raddr = rptr[ADDR_WIDTH-1:0];

    // The upper pointer bit toggles each time the RAM address wraps.
    assign rempty = (wptr == rptr);
    assign wfull = (waddr == raddr) && (wptr[ADDR_WIDTH] != rptr[ADDR_WIDTH]);

    wire wenc = rst_n && winc && !wfull;
    wire renc = rst_n && rinc && !rempty;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wptr <= 0;
            rptr <= 0;
        end else begin
            if (wenc) begin
                if (waddr == LAST_ADDR)
                    wptr <= {~wptr[ADDR_WIDTH], {ADDR_WIDTH{1'b0}}};
                else
                    wptr <= wptr + 1'b1;
            end
            if (renc) begin
                if (raddr == LAST_ADDR)
                    rptr <= {~rptr[ADDR_WIDTH], {ADDR_WIDTH{1'b0}}};
                else
                    rptr <= rptr + 1'b1;
            end
        end
    end

    TopModule_dual_port_RAM #(.DEPTH(DEPTH), .WIDTH(WIDTH)) u_ram (
        .wclk(clk),
        .wenc(wenc),
        .waddr(waddr),
        .wdata(wdata),
        .rclk(clk),
        .renc(renc),
        .raddr(raddr),
        .rdata(rdata)
    );

endmodule

module TopModule_dual_port_RAM #(
    parameter DEPTH = 16,
    parameter WIDTH = 8,
    localparam ADDR_WIDTH = (DEPTH > 1) ? $clog2(DEPTH) : 1
)(
    input wclk,
    input wenc,
    input [ADDR_WIDTH-1:0] waddr,
    input [WIDTH-1:0] wdata,
    input rclk,
    input renc,
    input [ADDR_WIDTH-1:0] raddr,
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
