module TopModule
(
    input rst_n, //Asynchronous reset signal, active low
    input clk, 	//Clock signal
    input [9:0]money,
    input set,
    input boost,
    output reg[9:0]remain,
    output reg yellow,
    output reg red
);
    wire [9:0] rate = boost ? 10'd2 : 10'd1;

    always @* begin
        yellow = rst_n && (remain != 10'd0) && (remain < 10'd10);
        red = rst_n && (remain < rate);
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            remain <= 10'd0;
        else if (set)
            remain <= remain + money;
        else if (remain >= rate)
            remain <= remain - rate;
    end
endmodule
