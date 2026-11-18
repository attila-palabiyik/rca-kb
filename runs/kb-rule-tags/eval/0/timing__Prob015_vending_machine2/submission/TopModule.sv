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
    localparam [2:0] PRICE1 = 3'd3;
    localparam [2:0] PRICE2 = 3'd5;

    reg d1_sample, d2_sample;
    reg d1_previous, d2_previous;
    wire d1_pulse = d1_sample & ~d1_previous;
    wire d2_pulse = d2_sample & ~d2_previous;

    // Credit and change are measured in half-yuan coins.
    reg [2:0] credit;
    reg [2:0] change_pending;
    wire [2:0] deposit = {1'b0, d2_pulse, d1_pulse};
    wire [2:0] price = sel ? PRICE2 : PRICE1;
    wire vend = credit >= price;
    wire [2:0] change_due = change_pending + (vend ? credit - price : 3'd0);

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            d1_sample <= 1'b0;
            d2_sample <= 1'b0;
            out1 <= 1'b0;
            out2 <= 1'b0;
            out3 <= 1'b0;
            change_pending <= 3'd0;
        end else begin
            d1_sample <= d1;
            d2_sample <= d2;
            out1 <= vend && !sel;
            out2 <= vend && sel;
            out3 <= change_due != 3'd0;
            change_pending <= (change_due != 3'd0) ? change_due - 3'd1 : 3'd0;
        end
    end

    always @(negedge clk or negedge rst) begin
        if (!rst) begin
            d1_previous <= 1'b0;
            d2_previous <= 1'b0;
            credit <= 3'd0;
        end else begin
            // Consume the pulses before updating the history that clears them.
            d1_previous <= d1_sample;
            d2_previous <= d2_sample;
            // Coins sampled on a dispensing edge start the next purchase.
            credit <= ((out1 || out2) ? 3'd0 : credit) + deposit;
        end
    end
endmodule
