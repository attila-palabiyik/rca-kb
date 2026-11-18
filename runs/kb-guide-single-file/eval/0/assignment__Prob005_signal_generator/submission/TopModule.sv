module TopModule(
	input clk,
	input rst_n,
	input [1:0] wave_choice,
	output reg [4:0]wave
	);

    reg [4:0] cnt;
    reg flag;
    wire triangle_up = wave == 5'd0 || (wave < 5'd20 && !flag);
    
  	// Square wave mode, counter control
    always@(posedge clk or negedge rst_n) begin
        if(~rst_n)
            cnt <= 0;
        else
            cnt <= wave_choice!=0 ? 0:
                   cnt        ==20? 0:
                   cnt + 1;
    end
    
    // Remember whether the triangle is descending between endpoints.
    always@(posedge clk or negedge rst_n) begin
        if(~rst_n)
            flag <= 0;
        else
            flag <= wave_choice == 2'd2 && !triangle_up;
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
                2      : wave <= triangle_up ? wave + 5'd1 : wave - 5'd1;
                default: wave <= 0;
            endcase
    end
endmodule
