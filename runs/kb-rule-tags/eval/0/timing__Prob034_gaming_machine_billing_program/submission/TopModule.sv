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
    wire [10:0] available_balance;
    wire [10:0] cycle_cost;

    assign available_balance = {1'b0, remain} + (set ? {1'b0, money} : 11'd0);
    assign cycle_cost = boost ? 11'd2 : 11'd1;

    always @(*) begin
      if (~rst_n) begin
        yellow = 1'b0;
        red    = 1'b0;
      end
      else begin
        yellow = (remain < 10) && remain;
        red    = boost ? (remain < 2) : (remain < 1);
      end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            remain <= 10'd0;
        else if (available_balance >= cycle_cost)
            remain <= 10'(available_balance - cycle_cost);
        else
            remain <= available_balance[9:0];
    end
endmodule
