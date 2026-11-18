module TopModule(
     input  wire clk_in,
     input  wire rst,
     output wire clk_out
);
    parameter M_N = 8'd87; 
    parameter c89 = 8'd24;  // 8/9 clock switching point
    parameter div_e = 5'd8; //Even period
    parameter div_o = 5'd9; //Odd period

    // Each segment spans whole output periods: c89 is a multiple of
    // div_e, and M_N - c89 is a multiple of div_o.
    localparam MAX_PERIOD = (div_e > div_o) ? div_e : div_o;
    localparam CLK_CNT_WIDTH = (MAX_PERIOD > 1) ? $clog2(MAX_PERIOD) : 1;
    localparam CYC_CNT_WIDTH = (M_N > 1) ? $clog2(M_N) : 1;

    reg [CLK_CNT_WIDTH-1:0] clk_cnt;
    reg [CYC_CNT_WIDTH-1:0] cyc_cnt;
    reg div_flag;
    reg clk_out_r;

    wire [$clog2(MAX_PERIOD + 1)-1:0] period = div_flag ? div_o : div_e;

    always @(posedge clk_in or negedge rst) begin
        if (!rst) begin
            clk_cnt <= 0;
            cyc_cnt <= 0;
            div_flag <= (c89 == 0);
            clk_out_r <= 1'b0;
        end else begin
            clk_cnt <= (clk_cnt == period - 1'b1) ? 0 : clk_cnt + 1'b1;
            clk_out_r <= (clk_cnt < (period >> 1));

            // Switch after counting the last input cycle of the current segment.
            if (cyc_cnt == M_N - 1) begin
                cyc_cnt <= 0;
                div_flag <= (c89 == 0);
            end else begin
                cyc_cnt <= cyc_cnt + 1'b1;
                if (cyc_cnt == c89 - 1)
                    div_flag <= 1'b1;
            end
        end
    end

    assign clk_out = clk_out_r;
endmodule
