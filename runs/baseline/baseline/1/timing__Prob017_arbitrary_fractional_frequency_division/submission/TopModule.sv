module TopModule(
     input  wire clk_in,
     input  wire rst,
     output wire clk_out
);
    parameter M_N = 8'd87;
    parameter c89 = 8'd24;  // Input cycles spent using div_e
    parameter div_e = 5'd8;
    parameter div_o = 5'd9;

    localparam MAX_DIV = (div_e > div_o) ? div_e : div_o;
    localparam CLK_CNT_WIDTH = (MAX_DIV > 1) ? $clog2(MAX_DIV) : 1;
    localparam CYC_CNT_WIDTH = (M_N > 1) ? $clog2(M_N) : 1;

    reg [CLK_CNT_WIDTH-1:0] clk_cnt;
    reg [CYC_CNT_WIDTH-1:0] cyc_cnt;
    reg clk_out_r;

    // Each segment contains whole output periods. By default, the first
    // 24 input cycles give three periods and the next 63 give seven.
    wire use_div_e = (cyc_cnt < c89);
    localparam [CLK_CNT_WIDTH-1:0] LAST_E = CLK_CNT_WIDTH'(div_e - 1);
    localparam [CLK_CNT_WIDTH-1:0] LAST_O = CLK_CNT_WIDTH'(div_o - 1);
    localparam [CLK_CNT_WIDTH-1:0] HIGH_E = CLK_CNT_WIDTH'(div_e >> 1);
    localparam [CLK_CNT_WIDTH-1:0] HIGH_O = CLK_CNT_WIDTH'(div_o >> 1);
    localparam [CYC_CNT_WIDTH-1:0] LAST_CYCLE = CYC_CNT_WIDTH'(M_N - 1);

    always @(posedge clk_in or negedge rst) begin
        if (!rst) begin
            clk_cnt <= 0;
            cyc_cnt <= 0;
            clk_out_r <= 1'b0;
        end else begin
            clk_cnt <= (clk_cnt == (use_div_e ? LAST_E : LAST_O)) ? 0 : clk_cnt + 1'b1;
            cyc_cnt <= (cyc_cnt == LAST_CYCLE) ? 0 : cyc_cnt + 1'b1;
            clk_out_r <= (clk_cnt < (use_div_e ? HIGH_E : HIGH_O));
        end
    end

    assign clk_out = clk_out_r;
endmodule
