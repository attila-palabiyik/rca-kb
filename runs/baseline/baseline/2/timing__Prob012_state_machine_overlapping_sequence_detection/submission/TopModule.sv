module TopModule(
	input wire clk  ,
	input wire rst  ,
	input wire data ,
	output reg flag
);
//*************code***********//
    parameter S0=0, S1=1, S2=2, S3=3, S4=4;
    reg [2:0] state, nstate;
    
    always@(posedge clk or negedge rst) begin
        if (!rst) begin
            state <= S0;
            flag <= 1'b0;
        end else begin
            state <= nstate;
            flag <= (state == S4);
        end
    end
    
    always@(*) begin
        case (state)
            S0     : nstate = data ? S1 : S0;
            S1     : nstate = data ? S1 : S2;
            S2     : nstate = data ? S3 : S0;
            S3     : nstate = data ? S4 : S2;
            S4     : nstate = data ? S1 : S2;
            default: nstate = S0;
        endcase
    end


//*************code***********//
endmodule
