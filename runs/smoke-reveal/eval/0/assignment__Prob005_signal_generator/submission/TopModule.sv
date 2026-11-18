module TopModule(
	input clk,
	input rst_n,
	input [1:0] wave_choice,
	output reg [4:0]wave
	);

    reg [4:0] cnt;
    reg triangle_falling;
    wire triangle_step_down = (wave == 5'd20) ||
                              (triangle_falling && wave != 5'd0);
    
  	// Square wave mode, counter control
    always@(posedge clk or negedge rst_n) begin
        if(~rst_n)
            cnt <= 0;
        else
            cnt <= wave_choice!=0 ? 0:
                   cnt        ==20? 0:
                   cnt + 1;
    end
    
    // Remember the direction taken at each triangle endpoint.
    always@(posedge clk or negedge rst_n) begin
        if(~rst_n)
            triangle_falling <= 1'b0;
        else
            triangle_falling <= (wave_choice == 2'd2) && triangle_step_down;
    end
    
  
  	// Update wave signal
    always@(posedge clk or negedge rst_n) begin
        if(~rst_n) 
            wave <= 0;
        else 
            case(wave_choice)
                0      : wave <= cnt == 9? 20    : 
                                 cnt ==20? 0     :
                                 wave;
                1      : wave <= wave==20? 0     : wave+1;
                2      : wave <= triangle_step_down ? wave - 5'd1 : wave + 5'd1;
                default: wave <= 0;
            endcase
    end
endmodule
