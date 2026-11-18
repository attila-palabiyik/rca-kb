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
    reg [1:0] sampled_coins, previous_coins;
    reg [2:0] credit, change_due;

    // Each newly sampled coin stays asserted until the falling edge.
    wire [1:0] coin_pulse = sampled_coins & ~previous_coins;

    // Amounts are measured in 0.5-yuan units.
    wire [2:0] inserted = {1'b0, coin_pulse[1], 1'b0} +
                          {2'b00, coin_pulse[0]};
    wire [2:0] price = sel ? 3'd5 : 3'd3;
    wire vend = credit >= price;
    wire [2:0] change_total = change_due +
                              (vend ? credit - price : 3'd0);

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            sampled_coins <= 2'b00;
            change_due <= 3'd0;
            {out1, out2, out3} <= 3'b000;
        end else begin
            sampled_coins <= {d2, d1};
            out1 <= vend && !sel;
            out2 <= vend && sel;

            // An asserted out3 dispenses one coin at this clock cycle.
            out3 <= change_total != 3'd0;
            change_due <= (change_total != 3'd0) ? change_total - 3'd1 : 3'd0;
        end
    end

    always @(negedge clk or negedge rst) begin
        if (!rst) begin
            previous_coins <= 2'b00;
            credit <= 3'd0;
        end else begin
            previous_coins <= sampled_coins;
            // Coins sampled on a vending cycle start the next purchase.
            credit <= (out1 || out2) ? inserted : credit + inserted;
        end
    end
endmodule
