module TopModule
    (
		input rst_n, //Asynchronous reset signal, active low
        input clk, //Clock signal
        input pass_request,
		output reg [7:0] clock,
        output reg red,
		output reg yellow,
		output reg green
    );
	
	parameter 	idle = 2'd0,
				s1_red = 2'd1,
				s2_green = 2'd2,
				s3_yellow = 2'd3;
	reg [1:0] state;
	reg p_red,p_yellow,p_green;		//Buffer previous signal light values for rising edge detection


always @(posedge clk or negedge rst_n) 
    begin
        if(!rst_n)
        begin
			state <= s1_red;
			p_red <= 1'b1;
			p_green <= 1'b0;
			p_yellow <= 1'b0;			
        end
        else case(state)
		idle:
			begin
				p_red <= 1'b0;
				p_green <= 1'b0;
				p_yellow <= 1'b0;
				state <= s1_red;
			end
		s1_red:
			begin
				p_red <= 1'b1;
				p_green <= 1'b0;
				p_yellow <= 1'b0;
				if (clock == 8'd3)
					state <= s2_green;
				else
					state <= s1_red;
			end
		s2_green:
			begin
				p_red <= 1'b0;
				p_green <= 1'b1;
				p_yellow <= 1'b0;
				if (clock == 8'd3)
					state <= s3_yellow;
				else
					state <= s2_green;
			end
		s3_yellow:
			begin
				p_red <= 1'b0;
				p_green <= 1'b0;
				p_yellow <= 1'b1;
				if (clock == 8'd3)
					state <= s1_red;
				else
					state <= s3_yellow;
			end
		endcase
	end
 
always @(posedge clk or negedge rst_n) 
      if(!rst_n)
			clock <= 8'd10;
		else if (pass_request && green && (clock > 8'd10))
			clock <= 8'd10;
		else if (!green&&p_green)
			clock <= 8'd60;
		else if (!yellow&&p_yellow)
			clock <= 8'd5;
		else if (!red&&p_red)
			clock <= 8'd10;
		else clock <= clock - 8'd1;

always @(posedge clk or negedge rst_n) 
        if(!rst_n)
			begin
				yellow <= 1'd0;
				red <= 1'd1;
				green <= 1'd0;
			end
		else 
			begin
				yellow <= p_yellow;
				red <= p_red;
				green <= p_green;
			end		

endmodule


// Start each transition at 3 so the state updates at 2 and the buffered lights
// update at 1. The visible lights and countdown reload then update together.
