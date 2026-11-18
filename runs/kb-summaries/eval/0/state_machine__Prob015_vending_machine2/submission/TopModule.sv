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
    reg [1:0] sampled_coins;
    reg [1:0] previous_coins;

    wire [1:0] coin_inputs = {d2, d1};

    // A new coin is indicated from the rising sample until the falling edge.
    wire [1:0] coin_pulses = sampled_coins & ~previous_coins;

    // Express all amounts in units of 0.5 yuan.
    reg [2:0] credit;
    reg [2:0] pending_change;
    localparam [2:0] PRICE_1 = 3'd3, PRICE_2 = 3'd5;

    wire [2:0] price = sel ? PRICE_2 : PRICE_1;
    wire [2:0] total_at_sample = credit + {1'b0, (coin_inputs & ~previous_coins)};
    wire vend = total_at_sample >= price;

    // Settle the purchase from the captured coins and dispense outputs.
    wire [2:0] total = credit + {1'b0, coin_pulses};
    wire [2:0] overpayment = out1 ? total - PRICE_1 :
                             out2 ? total - PRICE_2 : 3'd0;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            sampled_coins <= 2'b00;
            {out1, out2, out3} <= 3'b000;
        end else begin
            sampled_coins <= coin_inputs;
            out1 <= vend && !sel;
            out2 <= vend && sel;
            // Each asserted clock cycle dispenses one change coin.
            out3 <= (pending_change != 3'd0) || (total_at_sample > price);
        end
    end

    always @(negedge clk or negedge rst) begin
        if (!rst) begin
            previous_coins <= 2'b00;
            credit <= 3'd0;
            pending_change <= 3'd0;
        end else begin
            previous_coins <= sampled_coins;
            credit <= (out1 || out2) ? 3'd0 : total;
            pending_change <= pending_change + overpayment - {2'b00, out3};
        end
    end
endmodule
