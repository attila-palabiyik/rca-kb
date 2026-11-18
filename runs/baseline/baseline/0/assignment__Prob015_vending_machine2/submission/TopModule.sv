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
    reg sampled_sel;

    // A newly sampled high generates a pulse until the falling edge.
    wire [1:0] coin_pulses = sampled_coins & ~previous_coins;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            sampled_coins <= 2'b00;
            sampled_sel <= 1'b0;
        end else begin
            sampled_coins <= {d2, d1};
            sampled_sel <= sel;
        end
    end

    // Credit, prices, and change are measured in half-yuan units.
    reg [2:0] credit, change_due;
    wire [2:0] total = credit + {1'b0, coin_pulses};
    wire [2:0] price = sampled_sel ? 3'd5 : 3'd3;
    wire vend = total >= price;
    wire [2:0] change = change_due + (vend ? total - price : 3'd0);

    always @(negedge clk or negedge rst) begin
        if (!rst) begin
            previous_coins <= 2'b00;
            credit <= 3'd0;
            change_due <= 3'd0;
            out1 <= 1'b0;
            out2 <= 1'b0;
            out3 <= 1'b0;
        end else begin
            previous_coins <= sampled_coins;
            credit <= vend ? 3'd0 : total;
            out1 <= vend && !sampled_sel;
            out2 <= vend && sampled_sel;
            out3 <= change != 3'd0;
            change_due <= change != 3'd0 ? change - 3'd1 : 3'd0;
        end
    end
endmodule
