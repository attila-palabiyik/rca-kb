module TopModule(
   input  clk,
   input  rst_n,
   output reg [3:0] gray_out
);
   reg advance;
   wire [3:0] gray_wire = gray_out;
   wire [3:0] binary;
   wire [3:0] next_binary;

   assign binary[3] = gray_wire[3];
   assign binary[2] = binary[3] ^ gray_wire[2];
   assign binary[1] = binary[2] ^ gray_wire[1];
   assign binary[0] = binary[1] ^ gray_wire[0];
   assign next_binary = binary + 4'd1;

   always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
         advance <= 1'b0;
         gray_out <= 4'b0000;
      end else begin
         advance <= ~advance;
         if (advance)
            gray_out <= next_binary ^ (next_binary >> 1);
      end
   end
endmodule
