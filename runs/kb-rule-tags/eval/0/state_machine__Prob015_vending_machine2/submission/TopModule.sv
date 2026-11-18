module TopModule(
    input  wire clk,
    input  wire rst,
    input  wire d1,
    input  wire d2,
    input  wire sel,

    output reg out1,
    output reg out2,
    output reg out3
);
    localparam [2:0] PRICE1 = 3'd3, PRICE2 = 3'd5;

    // A low level rearms each input, even between consecutive rising edges.
    reg coin1_seen, coin2_seen;

    always @(posedge clk or negedge rst or negedge d1) begin
        if (!rst || !d1)
            coin1_seen <= 1'b0;
        else
            coin1_seen <= 1'b1;
    end

    always @(posedge clk or negedge rst or negedge d2) begin
        if (!rst || !d2)
            coin2_seen <= 1'b0;
        else
            coin2_seen <= 1'b1;
    end

    // The balance and prices are measured in half-yuan units.
    reg [2:0] balance;
    wire [2:0] inserted = {1'b0, d2 & ~coin2_seen, d1 & ~coin1_seen};
    wire [2:0] price = sel ? PRICE2 : PRICE1;
    wire vend = balance >= price;
    wire [2:0] change = vend ? balance - price : 3'd0;

    reg [15:0] pending_change;
    wire [15:0] change_due = pending_change + {13'd0, change};
    wire dispense_change = change_due != 16'd0;
    reg previous_change;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            balance <= 3'd0;
            pending_change <= 16'd0;
            previous_change <= 1'b0;
        end
        else begin
            balance <= (vend ? 3'd0 : balance) + inserted;
            pending_change <= change_due - {15'd0, dispense_change};
            previous_change <= dispense_change;
        end
    end

    always @(*) begin
        out1 = rst && vend && !sel;
        out2 = rst && vend && sel;
        // Leave a low interval between consecutive change coins.
        out3 = rst && dispense_change && (!previous_change || !clk);
    end
endmodule
