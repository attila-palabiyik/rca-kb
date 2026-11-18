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
    reg [1:0] sampled_coins;
    reg [1:0] previous_coins;
    wire [1:0] coin_inputs = {d2, d1};
    wire [1:0] new_coins = coin_inputs & ~previous_coins;
    wire [1:0] coin_pulses = sampled_coins & ~previous_coins;

    // All amounts are in units of 0.5 yuan.
    reg [2:0] credit;
    reg [2:0] change_due;
    wire [2:0] total = credit + {1'b0, new_coins};
    wire [2:0] price = sel ? 3'd5 : 3'd3;
    wire vend = total >= price;
    wire [2:0] change_added = vend ? total - price : 3'd0;
    wire [2:0] change_available = change_due + change_added;

    // Record each rising sample during the high phase and clear its
    // pulse on the falling edge. A low sample rearms that coin input.
    always @(negedge clk or negedge rst) begin
        if (!rst)
            previous_coins <= 2'b00;
        else
            previous_coins <= (previous_coins & sampled_coins) | coin_pulses;
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            sampled_coins <= 2'b00;
            credit <= 3'd0;
            change_due <= 3'd0;
            out1 <= 1'b0;
            out2 <= 1'b0;
            out3 <= 1'b0;
        end else begin
            sampled_coins <= coin_inputs;
            credit <= vend ? 3'd0 : total;
            out1 <= vend && !sel;
            out2 <= vend && sel;

            // Each high output cycle dispenses one change coin.
            out3 <= change_available != 3'd0;
            change_due <= (change_available != 3'd0) ? change_available - 3'd1 : 3'd0;
        end
    end
endmodule
