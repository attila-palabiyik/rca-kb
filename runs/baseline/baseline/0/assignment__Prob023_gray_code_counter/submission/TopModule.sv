module TopModule(
   input   clk,
   input   rst_n,

   output  reg [3:0] gray_out
);
reg second_cycle;
wire [3:0] gray_wire = gray_out;
wire [3:0] bin_out;
wire [3:0] bin_incremented = bin_out + 4'd1;
wire [3:0] gray_next = bin_incremented ^ (bin_incremented >> 1);

assign bin_out[3] = gray_wire[3];
assign bin_out[2] = ^gray_wire[3:2];
assign bin_out[1] = ^gray_wire[3:1];
assign bin_out[0] = ^gray_wire[3:0];

always @(posedge clk or negedge rst_n) begin
   if (!rst_n) begin
      second_cycle <= 1'b0;
      gray_out <= 4'b0000;
   end else begin
      second_cycle <= ~second_cycle;
      if (second_cycle)
         gray_out <= gray_next;
   end
end
endmodule
