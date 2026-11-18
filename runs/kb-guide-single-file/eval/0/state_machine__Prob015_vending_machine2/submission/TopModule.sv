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
    localparam [2:0] PRICE_1 = 3'd3, PRICE_2 = 3'd5;

    reg [1:0] coin_sample, coin_previous;
    wire [1:0] coin_inputs = {d2, d1};
    wire [1:0] new_coins = coin_inputs & ~coin_previous;
    wire [1:0] coin_pulse = coin_sample & ~coin_previous;

    reg [2:0] balance;
    wire [2:0] total = balance + {1'b0, new_coins};
    wire [2:0] price = sel ? PRICE_2 : PRICE_1;
    wire vend = total >= price;
    wire [2:0] new_change = vend ? total - price : 3'd0;

    reg [3:0] change_pending;
    wire [3:0] change_available = change_pending + {1'b0, new_change};

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            coin_sample <= 2'b0;
            change_pending <= 4'd0;
            {out1, out2, out3} <= 3'b000;
        end else begin
            coin_sample <= coin_inputs;
            out1 <= vend && !sel;
            out2 <= vend && sel;

            // Each cycle with out3 high pays one half-yuan coin.
            out3 <= change_available != 4'd0;
            if (change_available != 4'd0)
                change_pending <= change_available - 4'd1;
            else
                change_pending <= 4'd0;
        end
    end

    // Keep the accepted coin pulses high from their sampling edge until
    // this edge, when the balance for the next purchase is saved.
    always @(negedge clk or negedge rst) begin
        if (!rst) begin
            coin_previous <= 2'b0;
            balance <= 3'd0;
        end else begin
            coin_previous <= coin_sample;
            if (out1 || out2)
                balance <= 3'd0;
            else
                balance <= balance + {1'b0, coin_pulse};
        end
    end
endmodule
