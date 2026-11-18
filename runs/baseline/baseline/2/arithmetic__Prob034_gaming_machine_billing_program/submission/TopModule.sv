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
    wire [9:0] charge = boost ? 10'd2 : 10'd1;
    reg [9:0] next_remain;

    always @* begin
        next_remain = remain;
        if (set)
            next_remain = remain + money;
        else if (remain >= charge)
            next_remain = remain - charge;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            remain <= 10'd0;
            yellow <= 1'b0;
            red    <= 1'b0;
        end else begin
            remain <= next_remain;
            yellow <= (next_remain != 10'd0) && (next_remain < 10'd10);
            red    <= next_remain < charge;
        end
    end
endmodule
