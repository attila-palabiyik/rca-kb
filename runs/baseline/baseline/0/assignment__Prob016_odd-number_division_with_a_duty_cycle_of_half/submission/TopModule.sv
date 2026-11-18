module TopModule
  #(parameter N = 7)
   (
    input    wire  rst ,
    input    wire  clk_in,
    output   wire  clk_out7
    );
   localparam COUNTER_WIDTH = (N > 1) ? $clog2(N) : 1;
   localparam [COUNTER_WIDTH-1:0] LAST_COUNT = COUNTER_WIDTH'(N - 1);
   localparam [COUNTER_WIDTH-1:0] RISE_COUNT = COUNTER_WIDTH'((N - 1) / 2);

   reg [COUNTER_WIDTH-1:0] cnt;
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

   reg clkp;
   always @(posedge clk_in or negedge rst) begin
      if (!rst) begin
         clkp <= 1'b0;
      end
      else if (cnt == RISE_COUNT) begin
         clkp <= 1'b1;
      end
      else if (cnt == LAST_COUNT) begin
         clkp <= 1'b0;
      end
   end

   generate
      if (N == 1) begin : divide_by_one
         assign clk_out7 = clk_in & rst;
      end
      else if (N % 2 == 0) begin : even_divider
         assign clk_out7 = clkp;
      end
      else begin : odd_divider
         reg clkn;
         always @(negedge clk_in or negedge rst) begin
            if (!rst)
               clkn <= 1'b0;
            else
               clkn <= clkp;
         end

         // Extend the high pulse by half an input clock cycle.
         assign clk_out7 = clkp | clkn;
      end
   endgenerate

endmodule
