module TopModule
  #(parameter N = 7)
   (
    input    wire  rst ,
    input    wire  clk_in,
    output   wire  clk_out7
    );
   localparam COUNT_WIDTH = (N > 1) ? $clog2(N) : 1;
   localparam [COUNT_WIDTH-1:0] LAST_COUNT = COUNT_WIDTH'(N - 1);
   localparam [COUNT_WIDTH-1:0] HIGH_START = COUNT_WIDTH'((N - 1) / 2);

   reg [COUNT_WIDTH-1:0] cnt;
   reg clkp;
   reg clkn;

   always @(posedge clk_in or negedge rst) begin
      if (!rst) begin
         cnt <= '0;
      end
      else if (cnt == LAST_COUNT) begin
         cnt <= '0;
      end
      else begin
         cnt <= cnt + 1'b1;
      end
   end

   always @(posedge clk_in or negedge rst) begin
      if (!rst) begin
         clkp <= 1'b0;
      end
      else begin
         clkp <= (cnt >= HIGH_START) && (cnt != LAST_COUNT);
      end
   end

   // For odd divisors, extend the high pulse by half an input cycle.
   always @(negedge clk_in or negedge rst) begin
      if (!rst) begin
         clkn <= 1'b0;
      end
      else begin
         clkn <= clkp;
      end
   end

   assign clk_out7 = (N == 1) ? (rst & clk_in) :
                     (N % 2 != 0) ? (clkp | clkn) : clkp;
endmodule
