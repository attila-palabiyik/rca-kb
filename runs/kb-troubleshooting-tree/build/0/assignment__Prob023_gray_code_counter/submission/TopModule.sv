module TopModule(
   input   clk,
   input   rst_n,

   output  reg [3:0] gray_out
);
// Feed back the registered Gray code, which starts at zero on reset.
wire [3:0] gray_wire = gray_out;
wire [3:0] bin_out;

assign bin_out[3] = gray_wire[3];
assign bin_out[2] = ^gray_wire[3:2];
assign bin_out[1] = ^gray_wire[3:1];
assign bin_out[0] = ^gray_wire[3:0];

reg [3:0] bin_incremented;

// The increment and output registers form a two-clock feedback loop.
always @(posedge clk or negedge rst_n) begin
   if (!rst_n) begin
      bin_incremented <= 4'b0;
      gray_out <= 4'b0;
   end
   else begin
      bin_incremented <= bin_out + 4'd1;
      gray_out <= (bin_incremented >> 1) ^ bin_incremented;
   end
end
endmodule
