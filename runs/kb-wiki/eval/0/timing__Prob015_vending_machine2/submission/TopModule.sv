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
    // All amounts are in units of 0.5 yuan.
    localparam [2:0] PRICE_1 = 3'd3;
    localparam [2:0] PRICE_2 = 3'd5;

    reg [1:0] sampled_coins, previous_coins;
    reg [2:0] credit, pending_change;

    // A new coin raises its pulse at the rising edge. Capturing the
    // sample as history at the falling edge clears the pulse.
    wire [1:0] coin_pulse = sampled_coins & ~previous_coins;
    wire [2:0] inserted = {1'b0, coin_pulse[1], coin_pulse[0]};
    wire [2:0] price = sel ? PRICE_2 : PRICE_1;
    wire vend = credit >= price;
    wire [2:0] sale_change = vend ? credit - price : 3'd0;
    wire [2:0] change_due = pending_change + sale_change;

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
            // Dispense one change coin per asserted output cycle.
            pending_change <= (change_due != 3'd0) ? change_due - 3'd1 : 3'd0;
        end
    end

    always @(negedge clk or negedge rst) begin
        if (!rst) begin
            previous_coins <= 2'b00;
            credit <= 3'd0;
        end else begin
            previous_coins <= sampled_coins;
            // Coins sampled on the dispensing edge start the next sale.
            credit <= (out1 || out2) ? inserted : credit + inserted;
        end
    end
endmodule
