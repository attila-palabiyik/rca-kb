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
    reg [1:0] coin_sample;
    reg [1:0] previous_coin_sample;
    wire [1:0] coin_pulse = coin_sample & ~previous_coin_sample;

    always @(posedge clk or negedge rst) begin
        if (!rst)
            coin_sample <= 2'b00;
        else
            coin_sample <= {d2, d1};
    end

    // Coin pulses last from the rising sample edge to the falling edge.
    always @(negedge clk or negedge rst) begin
        if (!rst)
            previous_coin_sample <= 2'b00;
        else
            previous_coin_sample <= coin_sample;
    end

    // Amounts are in units of 0.5 yuan.
    reg [2:0] credit;
    wire [2:0] inserted = {1'b0, coin_pulse[1], 1'b0}
                        + {2'b00, coin_pulse[0]};
    wire [2:0] price = sel ? 3'd5 : 3'd3;
    wire vend = credit >= price;

    always @(negedge clk or negedge rst) begin
        if (!rst)
            credit <= 3'd0;
        else if (out1 || out2)
            credit <= inserted; // New coins start the next purchase.
        else
            credit <= credit + inserted;
    end

    reg [3:0] change_due;
    wire [2:0] sale_change = vend ? credit - price : 3'd0;
    wire [3:0] total_change = change_due + {1'b0, sale_change};

    // Each clock cycle with out3 asserted pays one 0.5 yuan coin.
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            out1 <= 1'b0;
            out2 <= 1'b0;
            out3 <= 1'b0;
            change_due <= 4'd0;
        end else begin
            out1 <= vend && !sel;
            out2 <= vend && sel;
            out3 <= total_change != 4'd0;
            change_due <= total_change == 4'd0 ? 4'd0 : total_change - 4'd1;
        end
    end
endmodule
