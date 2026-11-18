module TopModule(
   input   clk,
   input   rst_n,

   output  reg [3:0] gray_out
);
   reg advance;
   wire [3:0] gray_wire;
   wire [3:0] binary_value;
   wire [3:0] next_binary;

   assign gray_wire = gray_out;
   assign binary_value[3] = gray_wire[3];
   assign binary_value[2] = ^gray_wire[3:2];
   assign binary_value[1] = ^gray_wire[3:1];
   assign binary_value[0] = ^gray_wire[3:0];
   assign next_binary = binary_value + 4'd1;

   always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
         advance <= 1'b0;
         gray_out <= 4'b0;
      end else begin
         advance <= ~advance;
         if (advance)
            gray_out <= (next_binary >> 1) ^ next_binary;
      end
   end
endmodule
