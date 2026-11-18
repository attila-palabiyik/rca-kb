module TopModule
  #(parameter N = 7)
   (
    input  wire rst,
    input  wire clk_in,
    output wire clk_out7
    );

   generate
      if (N == 1) begin : gen_bypass
         assign clk_out7 = rst & clk_in;
      end else begin : gen_divider
         localparam COUNT_WIDTH = $clog2(N);
         localparam [COUNT_WIDTH-1:0] LAST_COUNT = COUNT_WIDTH'(N - 1);
         localparam [COUNT_WIDTH-1:0] HIGH_START = COUNT_WIDTH'((N - 1) / 2);

         reg [COUNT_WIDTH-1:0] cnt;
         reg clkp;

         always @(posedge clk_in or negedge rst) begin
            if (!rst) begin
               cnt  <= '0;
               clkp <= 1'b0;
            end else if (cnt == LAST_COUNT) begin
               cnt  <= '0;
               clkp <= 1'b0;
            end else begin
               cnt <= cnt + 1'b1;
               if (cnt == HIGH_START)
                  clkp <= 1'b1;
            end
         end

         if (N % 2 == 1) begin : gen_odd
            reg clkn;

            always @(negedge clk_in or negedge rst) begin
               if (!rst)
                  clkn <= 1'b0;
               else if (cnt == HIGH_START)
                  clkn <= 1'b1;
               else if (cnt == LAST_COUNT)
                  clkn <= 1'b0;
            end

            // The falling-edge pulse starts half a cycle before clkp.
            assign clk_out7 = clkp | clkn;
         end else begin : gen_even
            assign clk_out7 = clkp;
         end
      end
   endgenerate
endmodule
