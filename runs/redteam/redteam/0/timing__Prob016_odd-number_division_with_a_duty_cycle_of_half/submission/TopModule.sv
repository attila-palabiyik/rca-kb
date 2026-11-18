module TopModule
  #(parameter N = 7)
   (
    input  wire rst,
    input  wire clk_in,
    output wire clk_out7
   );

   generate
      if (N == 1) begin : divide_by_one
         assign clk_out7 = rst & clk_in;
      end else begin : divider
         localparam COUNTER_WIDTH = $clog2(N);
         localparam HIGH_CYCLES = N / 2;

         reg [COUNTER_WIDTH-1:0] cnt;
         reg clkp;

         always @(posedge clk_in or negedge rst) begin
            if (!rst) begin
               cnt  <= 0;
               clkp <= 1'b0;
            end else begin
               if (cnt == N-1)
                  cnt <= 0;
               else
                  cnt <= cnt + 1'b1;

               if (cnt == N-1-HIGH_CYCLES)
                  clkp <= 1'b1;
               else if (cnt == N-1)
                  clkp <= 1'b0;
            end
         end

         if (N % 2) begin : odd_divisor
            reg clkn;

            always @(negedge clk_in or negedge rst) begin
               if (!rst)
                  clkn <= 1'b0;
               else
                  clkn <= clkp;
            end

            // Extend the high pulse by half an input cycle.
            assign clk_out7 = clkp | clkn;
         end else begin : even_divisor
            assign clk_out7 = clkp;
         end
      end
   endgenerate
endmodule
