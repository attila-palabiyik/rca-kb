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

    // The supplied RAM's address range is [-1:0] when DEPTH is 1.
    localparam ADDR_WIDTH = (DEPTH == 1) ? 2 : $clog2(DEPTH);
    localparam [ADDR_WIDTH-1:0] LAST_ADDR = ADDR_WIDTH'(DEPTH - 1);

    reg [ADDR_WIDTH:0] wptr;
    reg [ADDR_WIDTH:0] rptr;
    wire [ADDR_WIDTH-1:0] waddr = wptr[ADDR_WIDTH-1:0];
    wire [ADDR_WIDTH-1:0] raddr = rptr[ADDR_WIDTH-1:0];

    // The extra bit toggles on wrap to distinguish full from empty.
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

    dual_port_RAM #(.DEPTH(DEPTH), .WIDTH(WIDTH)) u_ram (
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
