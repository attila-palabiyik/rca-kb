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
    wire [10:0] funded_balance = {1'b0, remain} + (set ? {1'b0, money} : 11'd0);
    wire [10:0] rate = boost ? 11'd2 : 11'd1;
    wire [10:0] next_balance = (funded_balance >= rate) ? funded_balance - rate : funded_balance;

    always @(*) begin
        yellow = rst_n && (remain > 10'd0) && (remain < 10'd10);
        red = rst_n && ({1'b0, remain} < rate);
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            remain <= 10'd0;
        else
            remain <= next_balance[9:0];
    end
endmodule
