module TopModule (
    input wire clk,
    input wire rst,
    input wire d1,
    input wire d2,
    input wire sel,
    output reg out1,
    output reg out2,
    output reg out3
);
    localparam [2:0] PRICE1 = 3'd3, PRICE2 = 3'd5;

    reg [1:0] sampled_coins, previous_coins;
    wire [1:0] coin_pulses = sampled_coins & ~previous_coins;

    // All amounts are in units of 0.5 yuan.
    reg [2:0] balance;
    reg [2:0] change_due;
    wire [2:0] inserted = {2'b00, coin_pulses[0]}
                        + {1'b0, coin_pulses[1], 1'b0};
    wire [2:0] price = sel ? PRICE2 : PRICE1;
    wire vend = balance >= price;
    wire [2:0] change_total = change_due + (vend ? balance - price : 3'd0);

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            sampled_coins <= 2'b00;
            {out1, out2, out3} <= 3'b000;
            change_due <= 3'd0;
        end else begin
            sampled_coins <= {d2, d1};
            out1 <= vend && !sel;
            out2 <= vend && sel;
            out3 <= change_total != 3'd0;
            change_due <= (change_total != 3'd0) ? change_total - 3'd1 : 3'd0;
        end
    end

    // The falling edge ends the coin pulses and records their value.
    // Coins sampled on the dispensing edge start the next purchase.
    always @(negedge clk or negedge rst) begin
        if (!rst) begin
            previous_coins <= 2'b00;
            balance <= 3'd0;
        end else begin
            previous_coins <= sampled_coins;
            balance <= (out1 || out2) ? inserted : balance + inserted;
        end
    end
endmodule
