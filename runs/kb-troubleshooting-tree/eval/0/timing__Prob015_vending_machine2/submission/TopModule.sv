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
    reg [1:0] coins_sampled, coins_previous, coin_value;
    wire [1:0] coin_pulse = coins_sampled & ~coins_previous;

    always @(posedge clk or negedge rst) begin
        if (!rst)
            coins_sampled <= 2'b00;
        else
            coins_sampled <= {d2, d1};
    end

    // Capture the new coins and end their pulses on the falling edge.
    always @(negedge clk or negedge rst) begin
        if (!rst) begin
            coins_previous <= 2'b00;
            coin_value <= 2'd0;
        end else begin
            coins_previous <= coins_sampled;
            coin_value <= coin_pulse;
        end
    end

    // The balance and change are measured in half-yuan units.
    reg [2:0] balance, change_pending;
    wire [2:0] credit = balance + {1'b0, coin_value};
    wire [2:0] price = sel ? 3'd5 : 3'd3;
    wire vend = credit >= price;
    wire [2:0] new_change = vend ? credit - price : 3'd0;
    wire [2:0] change_due = change_pending + new_change;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            balance <= 3'd0;
            change_pending <= 3'd0;
            {out1, out2, out3} <= 3'b000;
        end else begin
            balance <= vend ? 3'd0 : credit;
            out1 <= vend && !sel;
            out2 <= vend && sel;

            // Each cycle with out3 asserted dispenses one coin.
            out3 <= change_due != 3'd0;
            change_pending <= (change_due != 3'd0) ? change_due - 3'd1 : 3'd0;
        end
    end
endmodule
