module TopModule(
	input clk,
	input rst_n,
	input [1:0] wave_choice,
	output reg [4:0]wave
	);

    reg [4:0] cnt;
    reg flag;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            cnt <= 5'd0;
        else if (wave_choice != 2'd0 || cnt == 5'd19)
            cnt <= 5'd0;
        else
            cnt <= cnt + 5'd1;
    end
    
    // Reverse direction as the registered wave reaches an endpoint.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            flag <= 1'b0;
        else if (wave_choice != 2'd2)
            flag <= 1'b0;
        else if (wave <= 5'd1)
            flag <= 1'b1;
        else if (wave == 5'd19)
            flag <= 1'b0;
    end
    
  
  	// Update wave signal
    always@(posedge clk or negedge rst_n) begin
        if(~rst_n) 
            wave <= 0;
        else 
            case(wave_choice)
                0      : wave <= cnt == 9? 20    : 
                                 cnt ==19? 0     :
                                 wave;
                1      : wave <= wave==20? 0     : wave+1;
                2      : wave <= (wave == 5'd0 || flag) ? wave + 5'd1 : wave - 5'd1;
                default: wave <= 0;
            endcase
    end
endmodule
