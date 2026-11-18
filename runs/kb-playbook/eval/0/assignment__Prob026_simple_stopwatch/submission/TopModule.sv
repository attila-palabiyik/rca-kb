module TopModule(
	input clk,
	input rst_n,
	output reg [5:0] second,
	output reg [5:0] minute
);
	always @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin
			second <= 6'd0;
			minute <= 6'd0;
		end else if (minute < 6'd60) begin
			if (second == 6'd60) begin
				second <= 6'd1;
				minute <= minute + 6'd1;
			end else begin
				second <= second + 6'd1;
			end
		end
	end
endmodule
