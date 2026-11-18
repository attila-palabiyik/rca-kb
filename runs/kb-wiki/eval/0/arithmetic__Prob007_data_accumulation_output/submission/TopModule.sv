module TopModule(
	input 				clk 		,   
	input 				rst_n		,
	input		[7:0]	data_in		,
	input				valid_a		,
	input	 			ready_b		,
 
 	output		 		ready_a		,
 	output	reg			valid_b		,
	output  reg [9:0] 	data_out
);
reg 	[1:0]		data_cnt;
wire                input_transfer;

assign ready_a = !valid_b | ready_b;
assign input_transfer = valid_a && ready_a;

always @(posedge clk or negedge rst_n ) begin
	if(!rst_n) 
		data_cnt <= 'd0;
	else if(input_transfer)
		data_cnt <= (data_cnt == 2'd3) ? 'd0 : (data_cnt + 1'd1);
end
always @(posedge clk or negedge rst_n ) begin
	if(!rst_n) 
		valid_b <= 'd0;
	else if(data_cnt == 2'd3 && input_transfer)
		valid_b <= 1'd1;
	else if(valid_b && ready_b)
		valid_b <= 1'd0;
end

always @(posedge clk or negedge rst_n ) begin
	if(!rst_n) 
		data_out <= 'd0;
	else if(input_transfer) begin
		if(data_cnt == 2'd0)
			data_out <= {2'b0, data_in};
		else
			data_out <= data_out + {2'b0, data_in};
	end
	
end


endmodule
