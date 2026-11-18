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
    wire [1:0] arriving_coins = coin_inputs & ~previous_coins;

    // A sampled rising edge stays high until the falling edge copies the sample.
    wire [1:0] coin_pulse = sampled_coins & ~previous_coins;

    always @(negedge clk or negedge rst) begin
        if (!rst)
            previous_coins <= 2'b00;
        else
            previous_coins <= sampled_coins;
    end

    // All amounts are measured in half-yuan units.
    reg [2:0] credit;
    reg [2:0] change_left;
    wire [2:0] deposit = {1'b0, arriving_coins[1], 1'b0}
                       + {2'b00, arriving_coins[0]};
    wire [2:0] price = sel ? 3'd5 : 3'd3;
    wire vend = credit >= price;
    wire [2:0] sale_change = vend ? credit - price : 3'd0;
    wire [3:0] change_due = {1'b0, change_left} + {1'b0, sale_change};

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            sampled_coins <= 2'b00;
            credit <= 3'd0;
            change_left <= 3'd0;
        end else begin
            sampled_coins <= coin_inputs;
            // Credit the same edges that become coin_pulse after this clock edge.
            credit <= (vend ? 3'd0 : credit) + deposit;
            change_left <= (change_due == 4'd0) ? 3'd0 : change_due - 4'd1;
        end
    end

    always @(*) begin
        out1 = rst && vend && !sel;
        out2 = rst && vend && sel;
        out3 = rst && (change_due != 4'd0);
    end
endmodule
