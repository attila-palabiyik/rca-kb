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
    wire [1:0] coin_pulses = sampled_coins & ~previous_coins;

    // All amounts are in units of 0.5 yuan.
    localparam [3:0] PRICE_1 = 4'd3, PRICE_2 = 4'd5;
    reg [3:0] credit;
    reg [3:0] change_due;
    wire [3:0] price = sel ? PRICE_2 : PRICE_1;
    wire can_vend = credit >= price;
    wire [3:0] new_change = can_vend ? credit - price : 4'd0;
    wire [3:0] change_available = change_due + new_change;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            sampled_coins <= 2'b00;
            change_due <= 4'd0;
            {out1, out2, out3} <= 3'b000;
        end else begin
            sampled_coins <= {d2, d1};

            out1 <= can_vend && !sel;
            out2 <= can_vend && sel;
            out3 <= change_available != 4'd0;
            // Each asserted cycle pays one 0.5-yuan coin.
            change_due <= change_available == 4'd0
                        ? 4'd0 : change_available - 4'd1;
        end
    end

    always @(negedge clk or negedge rst) begin
        if (!rst) begin
            previous_coins <= 2'b00;
            credit <= 4'd0;
        end else begin
            // Capture the pulses before updating their history and clearing them.
            previous_coins <= sampled_coins;
            credit <= ((out1 || out2) ? 4'd0 : credit) + {2'b00, coin_pulses};
        end
    end
endmodule
