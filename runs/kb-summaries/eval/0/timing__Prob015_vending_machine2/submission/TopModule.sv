module TopModule(
    input  wire clk,
    input  wire rst,
    input  wire d1,
    input  wire d2,
    input  wire sel,
    output reg  out1,
    output reg  out2,
    output reg  out3
);
    reg [1:0] sampled_coins, previous_coins;
    wire [1:0] coin_pulses = sampled_coins & ~previous_coins;

    // Amounts are measured in units of 0.5 yuan.
    reg [2:0] credit;
    wire [2:0] price = sel ? 3'd5 : 3'd3;
    wire vend = credit >= price;
    wire [2:0] refund = vend ? credit - price : 3'd0;
    reg [3:0] pending_change;
    wire [3:0] change_due = pending_change + {1'b0, refund};

    // A newly sampled coin is high until the falling edge records the sample.
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            sampled_coins <= 2'b00;
            out1 <= 1'b0;
            out2 <= 1'b0;
            out3 <= 1'b0;
            pending_change <= 4'd0;
        end else begin
            sampled_coins <= {d2, d1};
            out1 <= vend && !sel;
            out2 <= vend && sel;
            out3 <= change_due != 4'd0;
            pending_change <= change_due == 4'd0 ? 4'd0 : change_due - 4'd1;
        end
    end

    always @(negedge clk or negedge rst) begin
        if (!rst) begin
            previous_coins <= 2'b00;
            credit <= 3'd0;
        end else begin
            previous_coins <= sampled_coins;
            // Coins sampled on the vending edge start the next purchase.
            credit <= (out1 || out2 ? 3'd0 : credit) + {1'b0, coin_pulses};
        end
    end
endmodule
