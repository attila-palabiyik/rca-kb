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
    // Amounts are measured in 0.5-yuan coins.
    localparam [3:0] PRICE_1 = 4'd3;
    localparam [3:0] PRICE_2 = 4'd5;

    reg d1_sample, d2_sample;
    reg d1_previous, d2_previous;
    reg [3:0] credit;
    reg [3:0] change_due;

    wire d1_pulse = d1_sample & ~d1_previous;
    wire d2_pulse = d2_sample & ~d2_previous;
    wire [3:0] inserted = {2'b00, d2_pulse, d1_pulse};

    wire [3:0] price = sel ? PRICE_2 : PRICE_1;
    wire vend = (change_due == 4'd0) && (credit >= price);

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            d1_sample <= 1'b0;
            d2_sample <= 1'b0;
            {out1, out2, out3} <= 3'b000;
        end else begin
            d1_sample <= d1;
            d2_sample <= d2;
            out1 <= vend && !sel;
            out2 <= vend && sel;
            out3 <= (change_due != 4'd0) || (vend && credit > price);
        end
    end

    always @(negedge clk or negedge rst) begin
        if (!rst) begin
            d1_previous <= 1'b0;
            d2_previous <= 1'b0;
            credit <= 4'd0;
            change_due <= 4'd0;
        end else begin
            // Consume each pulse before advancing the history that clears it.
            d1_previous <= d1_sample;
            d2_previous <= d2_sample;

            if (out1 || out2) begin
                // Coins sampled on the dispensing edge start the next purchase.
                credit <= inserted;
                if (out3)
                    change_due <= credit - (out1 ? PRICE_1 : PRICE_2) - 4'd1;
            end else begin
                credit <= credit + inserted;
                if (out3)
                    change_due <= change_due - 4'd1;
            end
        end
    end
endmodule
