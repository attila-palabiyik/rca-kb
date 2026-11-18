module TopModule(
     input  wire clk_in,
     input  wire rst,
     output wire clk_out
);
    // Each part of the frame must contain whole output periods.
    parameter M_N = 8'd87;  // Input cycles per repeating frame
    parameter c89 = 8'd24;  // Input cycles at div_e before switching to div_o
    parameter div_e = 5'd8;
    parameter div_o = 5'd9;

    localparam MAX_PERIOD = (div_e > div_o) ? div_e : div_o;
    localparam CLK_CNT_WIDTH = (MAX_PERIOD > 1) ? $clog2(MAX_PERIOD) : 1;
    localparam CYC_CNT_WIDTH = (M_N > 1) ? $clog2(M_N) : 1;

    reg [CLK_CNT_WIDTH-1:0] clk_cnt;
    reg [CYC_CNT_WIDTH-1:0] cyc_cnt;
    reg clk_out_r;

    wire div_flag = (cyc_cnt >= c89);
    wire [$bits(MAX_PERIOD)-1:0] period = div_flag ? div_o : div_e;

    always @(posedge clk_in or negedge rst) begin
        if (!rst)
            clk_cnt <= '0;
        else if (clk_cnt == period - 1'b1)
            clk_cnt <= '0;
        else
            clk_cnt <= clk_cnt + 1'b1;
    end

    always @(posedge clk_in or negedge rst) begin
        if (!rst)
            cyc_cnt <= '0;
        else if (cyc_cnt == M_N - 1'b1)
            cyc_cnt <= '0;
        else
            cyc_cnt <= cyc_cnt + 1'b1;
    end

    always @(posedge clk_in or negedge rst) begin
        if (!rst)
            clk_out_r <= 1'b0;
        else
            clk_out_r <= (clk_cnt < (period >> 1));
    end

    assign clk_out = clk_out_r;
endmodule
