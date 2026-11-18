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
    reg [1:0] sampled_coins;
    reg [1:0] previous_coins;
    wire [1:0] coin_pulses = sampled_coins & ~previous_coins;

    // Credit, prices, and change are measured in 0.5 yuan units.
    reg [2:0] credit;
    reg [2:0] pending_change;
    wire [2:0] inserted = {2'b00, coin_pulses[0]}
                        + {1'b0, coin_pulses[1], 1'b0};
    wire [2:0] price = sel ? 3'd5 : 3'd3;
    wire vend = credit >= price;
    wire [2:0] new_change = vend ? credit - price : 3'd0;
    wire [2:0] change_due = pending_change + new_change;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            sampled_coins <= 2'b00;
            pending_change <= 3'd0;
            {out1, out2, out3} <= 3'b000;
        end else begin
            sampled_coins <= {d2, d1};
            out1 <= vend && !sel;
            out2 <= vend && sel;
            out3 <= change_due != 3'd0;
            pending_change <= change_due == 3'd0 ? 3'd0 : change_due - 3'd1;
        end
    end

    always @(negedge clk or negedge rst) begin
        if (!rst) begin
            previous_coins <= 2'b00;
            credit <= 3'd0;
        end else begin
            // Capture each rising input once, then clear its pulse.
            previous_coins <= sampled_coins;
            // Coins sampled in a vending cycle start the next purchase.
            credit <= ((out1 || out2) ? 3'd0 : credit) + inserted;
        end
    end
endmodule
