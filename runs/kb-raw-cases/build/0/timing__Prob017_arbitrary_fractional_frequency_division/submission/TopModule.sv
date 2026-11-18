module TopModule(
     input  wire clk_in,
     input  wire rst,
     output wire clk_out
);
    parameter M_N = 8'd87; 
    parameter c89 = 8'd24;  // 8/9 clock switching point
    parameter div_e = 5'd8; //Even period
    parameter div_o = 5'd9; //Odd period
//*************code***********//
    localparam MAX_PERIOD = (div_e > div_o) ? div_e : div_o;
    localparam PERIOD_WIDTH = (MAX_PERIOD > 1) ? $clog2(MAX_PERIOD) : 1;
    localparam FRAME_WIDTH = (M_N > 1) ? $clog2(M_N) : 1;

    reg [PERIOD_WIDTH-1:0] clk_cnt;
    reg [FRAME_WIDTH-1:0] cyc_cnt;
    reg clk_out_r;

    // Each segment contains whole output periods: c89 is a multiple of
    // div_e and M_N - c89 is a multiple of div_o.
    wire [PERIOD_WIDTH:0] period_length = (cyc_cnt < c89) ? div_e : div_o;

    always @(posedge clk_in or negedge rst) begin
        if (!rst) begin
            clk_cnt <= 0;
            cyc_cnt <= 0;
            clk_out_r <= 1'b0;
        end else begin
            clk_cnt <= (clk_cnt == period_length - 1) ? 0 : clk_cnt + 1'b1;
            cyc_cnt <= (cyc_cnt == M_N - 1) ? 0 : cyc_cnt + 1'b1;
            clk_out_r <= (clk_cnt < (period_length >> 1));
        end
    end
    
    assign clk_out = clk_out_r;
//*************code***********//
endmodule
