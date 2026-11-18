module TopModule(
	input 				clk 		,   
	input 				rst_n		,
	input				valid_in	,
	input	[23:0]		data_in		,
 
 	output	reg			valid_out	,
	output  reg [127:0]	data_out
);
    reg [3:0]   cnt;
    reg [127:0] data_lock;
    
    always@(posedge clk or negedge rst_n) begin
        if(~rst_n)
            cnt <= 0;
        else
            cnt <= ~valid_in? cnt:cnt+1;
    end
    
    always@(posedge clk or negedge rst_n) begin
        if(~rst_n)
            data_lock <= 0;
        else
            data_lock <= valid_in? {data_lock[103:0], data_in}: data_lock;
    end
    
    always@(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            valid_out <= 1'b0;
            data_out <= 128'b0;
        end else begin
            valid_out <= 1'b0;
            if (valid_in) begin
                // Sixteen input words contain exactly three output words.
                case (cnt)
                    4'd5: begin
                        data_out <= {data_lock[119:0], data_in[23:16]};
                        valid_out <= 1'b1;
                    end
                    4'd10: begin
                        data_out <= {data_lock[111:0], data_in[23:8]};
                        valid_out <= 1'b1;
                    end
                    4'd15: begin
                        data_out <= {data_lock[103:0], data_in};
                        valid_out <= 1'b1;
                    end
                    default: begin
                    end
                endcase
            end
        end
    end
endmodule
