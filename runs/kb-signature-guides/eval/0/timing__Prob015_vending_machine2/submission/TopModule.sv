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
    reg [1:0] coin_sample, previous_sample;
    wire [1:0] coin_pulse = coin_sample & ~previous_sample;

    // All amounts are in half-yuan units.
    reg [2:0] credit;
    reg [2:0] pending_change;
    wire [2:0] price = sel ? 3'd5 : 3'd3;
    wire vend = credit >= price;
    wire [2:0] overpayment = vend ? credit - price : 3'd0;
    wire [3:0] change_due = {1'b0, pending_change} + {1'b0, overpayment};
    wire [2:0] deposited = {2'b00, coin_pulse[0]} +
                           {1'b0, coin_pulse[1], 1'b0};

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            coin_sample <= 2'b00;
            pending_change <= 3'd0;
            {out1, out2, out3} <= 3'b000;
        end else begin
            coin_sample <= {d2, d1};
            out1 <= vend && !sel;
            out2 <= vend && sel;
            out3 <= change_due != 4'd0;

            // Return one half-yuan coin per clock while change is due.
            pending_change <= change_due == 4'd0 ? 3'd0 : change_due - 4'd1;
        end
    end

    always @(negedge clk or negedge rst) begin
        if (!rst) begin
            previous_sample <= 2'b00;
            credit <= 3'd0;
        end else begin
            // Consume the pulses as they end. Coins sampled on a vending
            // edge are credited toward the next purchase.
            previous_sample <= coin_sample;
            credit <= ((out1 || out2) ? 3'd0 : credit) + deposited;
        end
    end
endmodule
