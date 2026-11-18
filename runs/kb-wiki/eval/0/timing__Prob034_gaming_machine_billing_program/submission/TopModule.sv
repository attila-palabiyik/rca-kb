module TopModule
(
    input rst_n, 
    input clk, 	
    input [9:0]money,
    input set,
    input boost,
    output reg[9:0]remain,
    output reg yellow,
    output reg red
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            yellow <= 1'b0;
            red    <= 1'b0;
        end else begin
            yellow <= (remain != 10'd0) && (remain < 10'd10);
            red    <= boost ? (remain < 10'd2) : (remain == 10'd0);
        end
    end

    
    always@(posedge clk or negedge rst_n) begin
        if(~rst_n) 
            remain <= 0;
        else if(boost)
            remain <= set     ? remain+money:
                      remain<2? remain: 
                      remain-2;
        else
            remain <= set     ? remain+money:
                      remain<1? remain: 
                      remain-1;
    end
endmodule
