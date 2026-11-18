module TopModule(
   input  wire       clk,
   input  wire       rst_n,
   output reg  [3:0] gray_out
);
   reg advance;
   wire [3:0] gray_wire;
   wire [3:0] bin_value;
   wire [3:0] bin_next;

   assign gray_wire = gray_out;
   assign bin_value[3] = gray_wire[3];
   assign bin_value[2] = gray_wire[2] ^ bin_value[3];
   assign bin_value[1] = gray_wire[1] ^ bin_value[2];
   assign bin_value[0] = gray_wire[0] ^ bin_value[1];
   assign bin_next = bin_value + 4'd1;

   always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
         advance  <= 1'b0;
         gray_out <= 4'b0000;
      end else begin
         advance <= ~advance;
         if (advance)
            gray_out <= bin_next ^ (bin_next >> 1);
      end
   end
endmodule
