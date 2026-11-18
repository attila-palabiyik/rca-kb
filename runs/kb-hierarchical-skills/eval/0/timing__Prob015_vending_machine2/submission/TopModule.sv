module TopModule (
    input wire clk,
    input wire rst,
    input wire d1,
    input wire d2,
    input wire sel,

    output reg out1,
    output reg out2,
    output reg out3
);
    localparam [2:0] PRICE1 = 3'd3;
    localparam [2:0] PRICE2 = 3'd5;

    reg [1:0] coin_sample, previous_coin_sample;
    wire [1:0] coin_pulse = coin_sample & ~previous_coin_sample;
    wire [2:0] inserted = {2'b00, coin_pulse[0]} + {1'b0, coin_pulse[1], 1'b0};

    // All amounts are measured in half-yuan units.
    reg [2:0] credit;
    reg [2:0] pending_change;
    wire [2:0] price = sel ? PRICE2 : PRICE1;
    wire vend = credit >= price;
    wire [2:0] excess = vend ? credit - price : 3'd0;
    wire [2:0] change_due = pending_change + excess;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            coin_sample <= 2'b00;
            pending_change <= 3'd0;
            {out1, out2, out3} <= 3'b000;
        end else begin
            coin_sample <= {d2, d1};
            out1 <= vend && !sel;
            out2 <= vend && sel;
            out3 <= change_due != 3'd0;
            pending_change <= change_due == 3'd0 ? 3'd0 : change_due - 3'd1;
        end
    end

    // The new sample raises each coin pulse, and capturing it here ends the
    // pulse. Coins sampled on a dispensing cycle fund the next purchase.
    always @(negedge clk or negedge rst) begin
        if (!rst) begin
            previous_coin_sample <= 2'b00;
            credit <= 3'd0;
        end else begin
            previous_coin_sample <= coin_sample;
            credit <= ((out1 || out2) ? 3'd0 : credit) + inserted;
        end
    end
endmodule
