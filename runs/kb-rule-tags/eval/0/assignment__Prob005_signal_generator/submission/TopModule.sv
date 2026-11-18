module TopModule(
	input clk,
	input rst_n,
	input [1:0] wave_choice,
	output reg [4:0]wave
	);

    reg [4:0] cnt;
    reg descending;
    
  	// Square wave mode, counter control
    always@(posedge clk or negedge rst_n) begin
        if(~rst_n)
            cnt <= 0;
        else
            cnt <= wave_choice!=0 ? 0:
                   cnt        ==20? 0:
                   cnt + 1;
    end
    
    // Update the output and reverse the triangle as it leaves each endpoint.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wave <= 5'd0;
            descending <= 1'b0;
        end else begin
            if (wave_choice != 2'd2)
                descending <= 1'b0;

            case (wave_choice)
                2'd0: wave <= (cnt >= 5'd9 && cnt < 5'd20) ? 5'd20 : 5'd0;
                2'd1: wave <= (wave == 5'd20) ? 5'd0 : wave + 5'd1;
                2'd2: begin
                    if (wave == 5'd20) begin
                        wave <= wave - 5'd1;
                        descending <= 1'b1;
                    end else if (wave == 5'd0) begin
                        wave <= wave + 5'd1;
                        descending <= 1'b0;
                    end else begin
                        wave <= descending ? wave - 5'd1 : wave + 5'd1;
                    end
                end
                default: wave <= 5'd0;
            endcase
        end
    end
endmodule
