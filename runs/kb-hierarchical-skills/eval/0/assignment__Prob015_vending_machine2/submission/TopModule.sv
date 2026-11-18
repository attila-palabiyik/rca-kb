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
    reg d1_sampled, d2_sampled;
    reg d1_previous, d2_previous;

    // Each pulse begins with the rising-edge sample and ends when the
    // falling edge records that sample in the input history.
    wire d1_pulse = d1_sampled & ~d1_previous;
    wire d2_pulse = d2_sampled & ~d2_previous;

    always @(negedge clk or negedge rst) begin
        if (!rst) begin
            d1_previous <= 1'b0;
            d2_previous <= 1'b0;
        end else begin
            if (d1_pulse)
                d1_previous <= 1'b1;
            else if (!d1_sampled)
                d1_previous <= 1'b0;

            if (d2_pulse)
                d2_previous <= 1'b1;
            else if (!d2_sampled)
                d2_previous <= 1'b0;
        end
    end

    // Use half-yuan units. Unsold credit is at most 4, and one
    // rising edge can add up to 3 when both coin inputs rise.
    reg [2:0] credit;
    reg [2:0] change_due;
    wire take_d1 = d1 & ~d1_previous;
    wire take_d2 = d2 & ~d2_previous;
    wire [2:0] total = credit + {1'b0, take_d2, take_d1};
    wire [2:0] price = sel ? 3'd5 : 3'd3;
    wire vend = total >= price;
    wire [2:0] refund = vend ? total - price : 3'd0;
    wire [2:0] change_total = change_due + refund;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            d1_sampled <= 1'b0;
            d2_sampled <= 1'b0;
            credit <= 3'd0;
            change_due <= 3'd0;
            {out1, out2, out3} <= 3'b000;
        end else begin
            d1_sampled <= d1;
            d2_sampled <= d2;
            credit <= vend ? 3'd0 : total;
            out1 <= vend & ~sel;
            out2 <= vend & sel;
            out3 <= change_total != 3'd0;
            change_due <= change_total == 3'd0 ? 3'd0 : change_total - 3'd1;
        end
    end
endmodule
