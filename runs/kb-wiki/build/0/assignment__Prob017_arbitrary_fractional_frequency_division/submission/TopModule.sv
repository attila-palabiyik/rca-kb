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
    localparam CLK_CNT_WIDTH = $clog2((div_e > div_o) ? div_e : div_o);
    localparam CYC_CNT_WIDTH = (M_N > 1) ? $clog2(M_N) : 1;

    reg [CLK_CNT_WIDTH-1:0] clk_cnt;
    reg [CYC_CNT_WIDTH-1:0] cyc_cnt;
    reg clk_out_r;

    // Configure c89 as a multiple of div_e and M_N - c89 as a multiple of div_o.
    wire div_flag = (cyc_cnt >= c89);
    wire [CLK_CNT_WIDTH:0] period = div_flag ? div_o : div_e;
    
    always@(posedge clk_in or negedge rst) begin
        if(~rst)
            clk_cnt <= 0;
        else
            clk_cnt <= (clk_cnt == period - 1) ? 0 : clk_cnt + 1;
    end
    
    always@(posedge clk_in or negedge rst) begin
        if(~rst)
            cyc_cnt <= 0;
        else
            cyc_cnt <= cyc_cnt==(M_N-1)? 0: cyc_cnt+1;
    end
    
    always@(posedge clk_in or negedge rst) begin
        if(~rst)
            clk_out_r <= 0;
        else
            clk_out_r <= clk_cnt < (period >> 1);
    end
    
    assign clk_out = clk_out_r;
//*************code***********//
endmodule
