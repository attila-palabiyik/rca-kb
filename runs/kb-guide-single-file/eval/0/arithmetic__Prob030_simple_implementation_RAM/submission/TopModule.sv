module TopModule(
	input clk,
	input rst_n,
	
	input write_en,
	input [7:0]write_addr,
    input [3:0]write_data,
	
	input read_en,
	input [7:0]read_addr,
	output reg [3:0]read_data
);
    reg [3:0] myRAM [7:0];
    
    reg [8:0] i;
    always@(posedge clk or negedge rst_n) begin
        if(~rst_n)
            for(i=0;i<8;i=i+1)
                myRAM[i] <= 4'b0000;
        else if(write_en)
            myRAM[write_addr] <= write_data;
    end
    always@(posedge clk or negedge rst_n) begin
        if(~rst_n)
            read_data <= 0;
        else
            read_data <= read_en? myRAM[read_addr]: read_data;
    end
endmodule
