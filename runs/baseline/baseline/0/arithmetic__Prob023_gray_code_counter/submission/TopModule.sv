module TopModule(
   input  wire       clk,
   input  wire       rst_n,
   output reg  [3:0] gray_out
);
   reg        advance;
   wire [3:0] gray_wire;
   wire [3:0] binary;
   wire [3:0] binary_next;
   wire [3:0] gray_next;

   // The reset value of gray_out also initializes the Gray code input.
   assign gray_wire = gray_out;
   assign binary[3] = gray_wire[3];
   assign binary[2] = gray_wire[2] ^ binary[3];
   assign binary[1] = gray_wire[1] ^ binary[2];
   assign binary[0] = gray_wire[0] ^ binary[1];

   assign binary_next = binary + 4'd1;
   assign gray_next = binary_next ^ (binary_next >> 1);

   always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
         gray_out <= 4'b0000;
         advance  <= 1'b0;
      end else begin
         advance <= ~advance;
         if (advance)
            gray_out <= gray_next;
      end
   end
endmodule
