module TopModule(
	input clk,
	input rst_n,
	input [1:0] wave_choice,
	output reg [4:0]wave
	);

    reg [4:0] cnt;
    reg rising;
    
  	// Square wave mode, counter control
    always@(posedge clk or negedge rst_n) begin
        if(~rst_n)
            cnt <= 0;
        else
            cnt <= wave_choice!=0 ? 0:
                   cnt        ==20? 0:
                   cnt + 1;
    end
    
    // Remember the triangle's direction between its endpoints.
    always@(posedge clk or negedge rst_n) begin
        if (!rst_n)
            rising <= 1'b1;
        else if (wave_choice != 2'd2 || wave == 5'd0)
            rising <= 1'b1;
        else if (wave == 5'd20)
            rising <= 1'b0;
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
                2'd2   : begin
                    if (wave == 5'd0)
                        wave <= 5'd1;
                    else if (wave == 5'd20)
                        wave <= 5'd19;
                    else if (rising)
                        wave <= wave + 5'd1;
                    else
                        wave <= wave - 5'd1;
                end
                default: wave <= 0;
            endcase
    end
endmodule
