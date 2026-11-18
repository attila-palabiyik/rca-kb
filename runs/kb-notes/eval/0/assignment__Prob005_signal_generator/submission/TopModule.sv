module TopModule(
	input clk,
	input rst_n,
	input [1:0] wave_choice,
	output reg [4:0]wave
	);

    reg [4:0] cnt;
    reg triangle_rising;
    wire triangle_step_up = (wave == 5'd0) ||
                            (triangle_rising && wave != 5'd20);
    
  	// Square wave mode, counter control
    always@(posedge clk or negedge rst_n) begin
        if(~rst_n)
            cnt <= 0;
        else
            cnt <= wave_choice!=0 ? 0:
                   cnt        ==20? 0:
                   cnt + 1;
    end
    
    // Save the direction used for this step until the next endpoint.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            triangle_rising <= 1'b1;
        else
            triangle_rising <= (wave_choice == 2'd2) ? triangle_step_up : 1'b1;
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
                2      : wave <= triangle_step_up ? wave + 5'd1 : wave - 5'd1;
                default: wave <= 0;
            endcase
    end
endmodule
