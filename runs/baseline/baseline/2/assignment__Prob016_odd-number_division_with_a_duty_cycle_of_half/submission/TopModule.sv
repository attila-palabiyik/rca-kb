module TopModule
  #(parameter N = 7)
   (
    input    wire  rst ,
    input    wire  clk_in,
    output   wire  clk_out7
    );



   localparam CNT_WIDTH = (N > 1) ? $clog2(N) : 1;
   reg [CNT_WIDTH-1:0] cnt;
   always @(posedge clk_in or negedge rst) begin
      if (!rst) begin
         cnt    <= 'b0 ;
      end
      else if (cnt == N-1) begin
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
      else if (cnt == (N-1)/2) begin
        clkp <= 1 ;
      end
      else if (cnt == N-1) begin 
        clkp <= 0 ;
      end
   end
  

   generate
      if (N == 1) begin : divide_by_one
         assign clk_out7 = clk_in & rst;
      end
      else if (N % 2 == 0) begin : even_divisor
         assign clk_out7 = clkp;
      end
      else begin : odd_divisor
         reg clkn;
         always @(negedge clk_in or negedge rst) begin
            if (!rst)
               clkn <= 1'b0;
            else
               clkn <= clkp;
         end

         // Extend the rising-edge pulse by half an input cycle.
         assign clk_out7 = clkp | clkn;
      end
   endgenerate


endmodule
