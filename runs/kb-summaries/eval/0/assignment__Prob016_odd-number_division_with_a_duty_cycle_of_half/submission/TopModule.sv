module TopModule
  #(parameter N = 7)
   (
    input    wire  rst ,
    input    wire  clk_in,
    output   wire  clk_out7
    );



   localparam CNT_WIDTH = (N > 1) ? $clog2(N) : 1;
   localparam [CNT_WIDTH-1:0] LAST_COUNT = CNT_WIDTH'(N - 1);
   localparam [CNT_WIDTH-1:0] HIGH_START = CNT_WIDTH'(N - 1 - N / 2);
   reg [CNT_WIDTH-1:0] cnt;
   always @(posedge clk_in or negedge rst) begin
      if (!rst) begin
         cnt    <= 'b0 ;
      end
      else if (cnt == LAST_COUNT) begin
         cnt    <= 'b0 ;
      end
      else begin
         cnt    <= cnt + 1'b1 ;
      end
   end

   reg                  clkp ;
   always @(posedge clk_in or negedge rst) begin
      if (!rst) begin
         clkp <= 1'b0 ;
      end
      else if (cnt == HIGH_START) begin
         clkp <= 1'b1;
      end
      else if (cnt == LAST_COUNT) begin
         clkp <= 1'b0;
      end
   end
  

   // For odd N, extend the high pulse to the next falling edge.
   reg                  clkn ;
   always @(negedge clk_in or negedge rst) begin
      if (!rst) begin
         clkn <= 1'b0 ;
      end
      else begin
         clkn <= clkp;
      end
   end


   assign clk_out7 = (N == 1) ? (clk_in & rst) :
                     (N % 2 == 0) ? clkp : (clkp | clkn);


endmodule
