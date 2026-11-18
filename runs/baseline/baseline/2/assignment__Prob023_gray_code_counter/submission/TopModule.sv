module TopModule(
   input   clk,
   input   rst_n,

   output  reg [3:0] gray_out
);
reg advance;
wire [3:0] gray_wire;
wire [3:0] bin_out;
wire [3:0] bin_incremented;
wire [3:0] gray_next;

// Feed back the current Gray code, which starts at zero on reset.
assign gray_wire = gray_out;
assign bin_out[3] = gray_wire[3];
assign bin_out[2] = gray_wire[2] ^ bin_out[3];
assign bin_out[1] = gray_wire[1] ^ bin_out[2];
assign bin_out[0] = gray_wire[0] ^ bin_out[1];
assign bin_incremented = bin_out + 4'd1;
assign gray_next = bin_incremented ^ (bin_incremented >> 1);

always @(posedge clk or negedge rst_n) begin
   if (!rst_n) begin
      advance <= 1'b0;
      gray_out <= 4'd0;
   end else begin
      advance <= ~advance;
      if (advance)
         gray_out <= gray_next;
   end
end
endmodule
