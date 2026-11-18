module TopModule(
    input  wire clk_in,
    input  wire rst,
    output wire clk_out
);
    parameter M_N   = 8'd87;
    parameter c89   = 8'd24;
    parameter div_e = 5'd8;
    parameter div_o = 5'd9;

    localparam MAX_PERIOD = (div_e > div_o) ? div_e : div_o;
    localparam PERIOD_WIDTH = $clog2(MAX_PERIOD + 1);
    localparam FRAME_WIDTH = (M_N > 1) ? $clog2(M_N) : 1;

    reg [PERIOD_WIDTH-1:0] period_count;
    reg [FRAME_WIDTH-1:0] frame_count;
    reg clk_out_r;

    // Each segment spans complete output periods: 24 = 3 * 8, 63 = 7 * 9.
    wire [PERIOD_WIDTH-1:0] period_cycles;
    assign period_cycles = (frame_count < c89) ? div_e : div_o;

    always @(posedge clk_in or negedge rst) begin
        if (!rst) begin
            frame_count  <= 0;
            period_count <= 0;
            clk_out_r    <= 1'b0;
        end else begin
            if (frame_count == M_N - 1'b1)
                frame_count <= 0;
            else
                frame_count <= frame_count + 1'b1;

            if (period_count == period_cycles - 1'b1)
                period_count <= 0;
            else
                period_count <= period_count + 1'b1;

            clk_out_r <= period_count < (period_cycles >> 1);
        end
    end

    assign clk_out = clk_out_r;
endmodule
