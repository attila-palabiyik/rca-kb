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
    reg [1:0] coin_sample, previous_coin;
    wire [1:0] coin_input = {d2, d1};
    wire [1:0] new_coins = coin_input & ~previous_coin;
    wire [1:0] coin_pulse = coin_sample & ~previous_coin;

    // All amounts are in units of 0.5 yuan. The two coin bits
    // have weights of 2 and 1, so both inputs can be accepted at once.
    reg [2:0] credit;
    wire [2:0] total = credit + {1'b0, new_coins};
    wire [2:0] price = sel ? 3'd5 : 3'd3;
    wire vend = total >= price;
    wire [2:0] change = vend ? total - price : 3'd0;

    reg [2:0] pending_change;
    wire [2:0] change_due = pending_change + change;
    reg change_started, change_ended;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            coin_sample <= 2'b00;
            out1 <= 1'b0;
            out2 <= 1'b0;
            change_started <= 1'b0;
            pending_change <= 3'd0;
        end else begin
            coin_sample <= coin_input;
            out1 <= vend && !sel;
            out2 <= vend && sel;

            if (change_due != 0) begin
                change_started <= ~change_started;
                pending_change <= change_due - 3'd1;
            end
        end
    end

    // Commit the sampled coins at the falling edge, which also ends their pulses.
    always @(negedge clk or negedge rst) begin
        if (!rst) begin
            previous_coin <= 2'b00;
            credit <= 3'd0;
            change_ended <= 1'b0;
        end else begin
            previous_coin <= coin_sample;
            credit <= (out1 || out2) ? 3'd0 : credit + {1'b0, coin_pulse};
            change_ended <= change_started;
        end
    end

    // Give consecutive change coins distinct pulses.
    always @(*) begin
        out3 = rst && (change_started != change_ended);
    end
endmodule
