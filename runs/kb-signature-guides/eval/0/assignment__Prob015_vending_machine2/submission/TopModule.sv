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
    reg [2:0] credit;
    reg [2:0] change_pending;

    // Bit weights represent the coin values in units of half a yuan.
    wire [1:0] new_coins = {d2, d1} & ~previous_coins;
    wire [1:0] coin_pulses = sampled_coins & ~previous_coins;
    wire [2:0] total = credit + {1'b0, new_coins};
    wire [2:0] price = sel ? 3'd5 : 3'd3;
    wire vend = total >= price;
    wire [2:0] sale_change = vend ? total - price : 3'd0;
    wire [2:0] change_due = change_pending + sale_change;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            sampled_coins <= 2'b00;
            change_pending <= 3'd0;
            {out1, out2, out3} <= 3'b000;
        end else begin
            sampled_coins <= {d2, d1};
            out1 <= vend && !sel;
            out2 <= vend && sel;
            out3 <= change_due != 3'd0;
            change_pending <= change_due != 3'd0
                              ? change_due - 3'd1 : 3'd0;
        end
    end

    // Capture the coin history at the falling edge to end the coin pulses.
    // Settle the balance for the same transaction that drove the outputs.
    always @(negedge clk or negedge rst) begin
        if (!rst) begin
            previous_coins <= 2'b00;
            credit <= 3'd0;
        end else begin
            previous_coins <= sampled_coins;
            if (out1 || out2)
                credit <= 3'd0;
            else
                credit <= credit + {1'b0, coin_pulses};
        end
    end

endmodule
