module TopModule(
   input   clk,
   input   rst_n,

   output  reg [3:0] gray_out
);
reg        count_enable;
wire [3:0] gray_wire;
wire [3:0] bin_out;
wire [3:0] bin_next;

assign gray_wire = gray_out;
assign bin_out[3] = gray_wire[3];
assign bin_out[2] = bin_out[3] ^ gray_wire[2];
assign bin_out[1] = bin_out[2] ^ gray_wire[1];
assign bin_out[0] = bin_out[1] ^ gray_wire[0];
assign bin_next = bin_out + 4'd1;

always @(posedge clk or negedge rst_n) begin
   if (!rst_n) begin
      count_enable <= 1'b0;
      gray_out <= 4'b0;
   end else begin
      count_enable <= ~count_enable;
      if (count_enable)
         gray_out <= (bin_next >> 1) ^ bin_next;
   end
end
endmodule
