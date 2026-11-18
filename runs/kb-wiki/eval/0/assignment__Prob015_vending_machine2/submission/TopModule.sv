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

    // Amounts are in half-yuan units.
    localparam [2:0] PRICE_1 = 3'd3;
    localparam [2:0] PRICE_2 = 3'd5;

    reg [1:0] sampled_coins;
    reg [1:0] previous_coins;
    reg [2:0] credit;
    reg [3:0] pending_change;

    wire [1:0] coins_in = {d2, d1};
    wire [1:0] new_coins = coins_in & ~previous_coins;
    wire [1:0] coin_pulses = sampled_coins & ~previous_coins;

    // The two coin values are 2 and 1, so their bits directly encode the sum.
    wire [2:0] total = credit + {1'b0, new_coins};
    wire [2:0] price = sel ? PRICE_2 : PRICE_1;
    wire       vend = total >= price;
    wire [2:0] sale_change = vend ? total - price : 3'd0;
    wire [3:0] change_due = pending_change + {1'b0, sale_change};

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            sampled_coins  <= 2'b00;
            pending_change <= 4'd0;
            {out1, out2, out3} <= 3'b000;
        end else begin
            sampled_coins <= coins_in;
            out1 <= vend && !sel;
            out2 <= vend && sel;
            // Each asserted clock cycle dispenses one half-yuan coin.
            out3 <= (change_due != 4'd0);
            pending_change <= (change_due != 4'd0) ? change_due - 4'd1 : 4'd0;
        end
    end

    // The input samples start the pulses on the rising edge. Updating the
    // history on the falling edge ends the pulses after committing the credit.
    always @(negedge clk or negedge rst) begin
        if (!rst) begin
            previous_coins <= 2'b00;
            credit <= 3'd0;
        end else begin
            previous_coins <= sampled_coins;
            credit <= (out1 || out2) ? 3'd0 : credit + {1'b0, coin_pulses};
        end
    end

endmodule
