module TopModule(
    input  wire clk_in,
    input  wire rst,
    output reg  clk_out
);
    parameter M_N = 8'd87;  // Input ticks per repeating frame
    parameter c89 = 8'd24;  // Input ticks using div_e before switching to div_o
    parameter div_e = 5'd8;
    parameter div_o = 5'd9;

    localparam MAX_DIV = (div_e > div_o) ? div_e : div_o;
    localparam CLK_CNT_WIDTH = (MAX_DIV > 1) ? $clog2(MAX_DIV) : 1;
    localparam CYC_CNT_WIDTH = (M_N > 1) ? $clog2(M_N) : 1;

    reg [CLK_CNT_WIDTH-1:0] clk_cnt;
    reg [CYC_CNT_WIDTH-1:0] cyc_cnt;
    wire [$bits(MAX_DIV)-1:0] period_ticks;

    // Each segment contains whole output periods of its selected length.
    assign period_ticks = (cyc_cnt < c89) ? div_e : div_o;

    always @(posedge clk_in or negedge rst) begin
        if (!rst) begin
            clk_cnt <= 0;
            cyc_cnt <= 0;
            clk_out <= 0;
        end else begin
            if (clk_cnt == period_ticks - 1)
                clk_cnt <= 0;
            else
                clk_cnt <= clk_cnt + 1'b1;

            if (cyc_cnt == M_N - 1)
                cyc_cnt <= 0;
            else
                cyc_cnt <= cyc_cnt + 1'b1;

            clk_out <= clk_cnt < (period_ticks >> 1);
        end
    end
endmodule
