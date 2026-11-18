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
    wire [1:0] coin_inputs = {d2, d1};
    wire [1:0] new_coins = coin_inputs & ~previous_coins;

    // The sampled edges stay high until the falling edge copies the sample.
    wire [1:0] coin_pulse = sampled_coins & ~previous_coins;

    // All amounts are in units of 0.5 yuan.
    reg [2:0] credit;
    reg [3:0] pending_change;
    wire [2:0] price = sel ? 3'd5 : 3'd3;
    wire [2:0] total = credit + {1'b0, new_coins};
    wire vend = total >= price;
    wire [2:0] excess = vend ? total - price : 3'd0;
    wire [3:0] change_due = pending_change + {1'b0, excess};

    reg change_request, change_ack;
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            sampled_coins <= 2'b00;
            credit <= 3'd0;
            pending_change <= 4'd0;
            change_request <= 1'b0;
            out1 <= 1'b0;
            out2 <= 1'b0;
        end else begin
            sampled_coins <= coin_inputs;
            credit <= vend ? 3'd0 : total;
            out1 <= vend && !sel;
            out2 <= vend && sel;

            if (change_due != 4'd0) begin
                change_request <= ~change_request;
                pending_change <= change_due - 4'd1;
            end
        end
    end

    always @(negedge clk or negedge rst) begin
        if (!rst) begin
            previous_coins <= 2'b00;
            change_ack <= 1'b0;
        end else begin
            previous_coins <= sampled_coins;
            change_ack <= change_request;
        end
    end

    // A falling-edge acknowledgement separates consecutive change coins.
    always @* begin
        out3 = rst && (change_request != change_ack);
    end
endmodule
