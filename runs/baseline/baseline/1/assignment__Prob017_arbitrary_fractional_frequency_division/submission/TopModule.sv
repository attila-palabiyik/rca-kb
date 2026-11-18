module TopModule(
     input  wire clk_in,
     input  wire rst,
     output wire clk_out
);
    parameter M_N = 8'd87;
    parameter c89 = 8'd24;
    parameter div_e = 5'd8;
    parameter div_o = 5'd9;

    localparam PERIOD_WIDTH = $clog2((div_e > div_o ? div_e : div_o) + 1);
    localparam CYCLE_WIDTH = $clog2(M_N + 1);

    reg [PERIOD_WIDTH-1:0] clk_cnt;
    reg [CYCLE_WIDTH-1:0] cyc_cnt;
    reg clk_out_r;

    // Each section must contain whole periods of its selected divider.
    // The defaults give three 8-cycle periods and seven 9-cycle periods.
    wire [PERIOD_WIDTH-1:0] period_length =
        (cyc_cnt < c89) ? PERIOD_WIDTH'(div_e) : PERIOD_WIDTH'(div_o);

    always @(posedge clk_in or negedge rst) begin
        if (!rst) begin
            clk_cnt <= 0;
            cyc_cnt <= 0;
            clk_out_r <= 0;
        end else begin
            clk_cnt <= (clk_cnt == period_length - 1'b1) ? '0 : clk_cnt + 1'b1;
            cyc_cnt <= (cyc_cnt == M_N - 1'b1) ? '0 : cyc_cnt + 1'b1;
            clk_out_r <= clk_cnt < (period_length >> 1);
        end
    end

    assign clk_out = clk_out_r;
endmodule
