module TopModule(
    input wire clk,
    input wire rst,
    input wire d1,
    input wire d2,
    input wire sel,

    output reg out1,
    output reg out2,
    output reg out3
);
    localparam [2:0] PRICE1 = 3'd3;
    localparam [2:0] PRICE2 = 3'd5;

    reg sampled_d1, sampled_d2;
    reg previous_d1, previous_d2;
    reg [2:0] balance, change_left;

    // The rising-edge samples are acknowledged on the falling edge.
    wire coin1 = sampled_d1 & ~previous_d1;
    wire coin2 = sampled_d2 & ~previous_d2;
    wire [2:0] inserted = {1'b0, coin2, coin1};

    // All amounts are in units of 0.5 yuan.
    wire [2:0] selected_price = sel ? PRICE2 : PRICE1;
    wire vend = (change_left == 0) && (balance >= selected_price);
    wire [2:0] change_due = balance - (out2 ? PRICE2 : PRICE1);

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            sampled_d1 <= 1'b0;
            sampled_d2 <= 1'b0;
            {out1, out2, out3} <= 3'b000;
        end else begin
            sampled_d1 <= d1;
            sampled_d2 <= d2;
            out1 <= vend && !sel;
            out2 <= vend && sel;
            out3 <= (change_left != 0) || (vend && balance > selected_price);
        end
    end

    always @(negedge clk or negedge rst) begin
        if (!rst) begin
            previous_d1 <= 1'b0;
            previous_d2 <= 1'b0;
            balance <= 3'd0;
            change_left <= 3'd0;
        end else begin
            previous_d1 <= sampled_d1;
            previous_d2 <= sampled_d2;

            if (out1 || out2) begin
                // The first change coin is dispensed with the beverage.
                balance <= inserted;
                change_left <= (change_due != 0) ? change_due - 3'd1 : 3'd0;
            end else begin
                balance <= balance + inserted;
                if (change_left != 0)
                    change_left <= change_left - 3'd1;
            end
        end
    end
endmodule
