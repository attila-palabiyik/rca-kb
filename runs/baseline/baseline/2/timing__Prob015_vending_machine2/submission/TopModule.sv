module TopModule (
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

    // Account for money in units of 0.5 yuan.
    reg  [2:0] credit;
    reg  [2:0] change_remaining;
    wire [2:0] deposit = {1'b0, coin_pulses[1], 1'b0}
                       + {2'b00, coin_pulses[0]};
    wire [2:0] price = sel ? 3'd5 : 3'd3;
    wire       vend = credit >= price;
    wire [2:0] change_due = change_remaining + (vend ? credit - price : 3'd0);

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            sampled_coins <= 2'b00;
            out1 <= 1'b0;
            out2 <= 1'b0;
            out3 <= 1'b0;
            change_remaining <= 3'd0;
        end else begin
            sampled_coins <= {d2, d1};
            out1 <= vend && !sel;
            out2 <= vend && sel;
            out3 <= change_due != 3'd0;
            change_remaining <= change_due != 3'd0 ? change_due - 3'd1 : 3'd0;
        end
    end

    // The sampled edge pulses last through the high phase of the clock.
    // Deposits sampled on a vending cycle start the next purchase.
    always @(negedge clk or negedge rst) begin
        if (!rst) begin
            previous_coins <= 2'b00;
            credit <= 3'd0;
        end else begin
            previous_coins <= sampled_coins;
            credit <= ((out1 || out2) ? 3'd0 : credit) + deposit;
        end
    end
endmodule
