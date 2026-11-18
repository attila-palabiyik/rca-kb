module TopModule(
   input clk,
   input rst_n,
   output reg [3:0] gray_out
);
   reg advance;
   wire [3:0] gray_wire = gray_out;
   wire [3:0] binary_value;
   wire [3:0] binary_next = binary_value + 4'd1;
   wire [3:0] gray_next = binary_next ^ (binary_next >> 1);

   assign binary_value[3] = gray_wire[3];
   assign binary_value[2] = binary_value[3] ^ gray_wire[2];
   assign binary_value[1] = binary_value[2] ^ gray_wire[1];
   assign binary_value[0] = binary_value[1] ^ gray_wire[0];

   always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
         gray_out <= 4'b0;
         advance <= 1'b0;
      end else begin
         advance <= ~advance;
         if (advance)
            gray_out <= gray_next;
      end
   end
endmodule
