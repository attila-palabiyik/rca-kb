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
    wire [1:0] new_coins = coin_inputs & ~previous_coins;
    wire [1:0] coin_pulse = sampled_coins & ~previous_coins;

    // Amounts are in units of 0.5 yuan.
    reg [2:0] credit;
    reg [2:0] pending_change;

    wire [2:0] price = sel ? 3'd5 : 3'd3;
    wire [2:0] total = credit + {1'b0, new_coins};
    wire vend = total >= price;
    wire [2:0] sale_change = vend ? total - price : 3'd0;
    wire [3:0] change_due = {1'b0, pending_change} + {1'b0, sale_change};
    wire give_change = change_due != 4'd0;

    // End each pulse at the falling edge and rearm inputs sampled low.
    always @(negedge clk or negedge rst) begin
        if (!rst)
            previous_coins <= 2'b00;
        else
            previous_coins <= (previous_coins | coin_pulse) & sampled_coins;
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            sampled_coins  <= 2'b00;
            credit         <= 3'd0;
            pending_change <= 3'd0;
            out1           <= 1'b0;
            out2           <= 1'b0;
            out3           <= 1'b0;
        end else begin
            sampled_coins  <= coin_inputs;
            credit         <= vend ? 3'd0 : total;
            pending_change <= give_change ? change_due - 4'd1 : 4'd0;
            out1           <= vend && !sel;
            out2           <= vend && sel;
            out3           <= give_change;
        end
    end
endmodule
