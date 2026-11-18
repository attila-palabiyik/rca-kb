module TopModule(
     input  wire clk_in,
     input  wire rst,
     output wire clk_out
);
    // Each segment contains whole periods: c89 is a multiple of div_e,
    // and M_N - c89 is a multiple of div_o.
    parameter M_N = 8'd87;
    parameter c89 = 8'd24;  // Input clocks before switching to div_o
    parameter div_e = 5'd8; //Even period
    parameter div_o = 5'd9; //Odd period
//*************code***********//
    localparam MAX_DIV = (div_e > div_o) ? div_e : div_o;
    localparam CLK_CNT_WIDTH = (MAX_DIV > 1) ? $clog2(MAX_DIV) : 1;
    localparam CYC_CNT_WIDTH = (M_N > 1) ? $clog2(M_N) : 1;

    reg [CLK_CNT_WIDTH-1:0] clk_cnt;
    reg [CYC_CNT_WIDTH-1:0] cyc_cnt;
    wire div_flag = (cyc_cnt >= c89);
    reg clk_out_r;
    
    always@(posedge clk_in or negedge rst) begin
        if(~rst)
            clk_cnt <= 0;
        else if(~div_flag)
            clk_cnt <= clk_cnt==(div_e-1)? 0: clk_cnt+1;
        else
            clk_cnt <= clk_cnt==(div_o-1)? 0: clk_cnt+1;
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
        else if(~div_flag)
            clk_out_r <= clk_cnt<=((div_e>>2)+1);
        else
            clk_out_r <= clk_cnt<=((div_o>>2)+1);
    end
    
    assign clk_out = clk_out_r;
//*************code***********//
endmodule
