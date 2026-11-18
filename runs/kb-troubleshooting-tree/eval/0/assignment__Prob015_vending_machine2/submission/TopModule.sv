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

    wire d1_rise = d1 & ~d1_previous;
    wire d2_rise = d2 & ~d2_previous;

    // The rising edge captures the input. The falling edge ends the pulse.
    wire d1_pulse = d1_sampled & ~d1_previous;
    wire d2_pulse = d2_sampled & ~d2_previous;

    always @(negedge clk or negedge rst) begin
        if (!rst) begin
            d1_previous <= 1'b0;
            d2_previous <= 1'b0;
        end else begin
            d1_previous <= d1_sampled;
            d2_previous <= d2_sampled;
        end
    end

    // Credit and change are counted in units of 0.5 yuan.
    reg [2:0] credit;
    reg [3:0] pending_change;

    wire [2:0] inserted = {1'b0, d2_rise, d1_rise};
    wire [2:0] total = credit + inserted;
    wire [2:0] price = sel ? 3'd5 : 3'd3;
    wire vend = total >= price;
    wire [2:0] new_change = vend ? total - price : 3'd0;
    wire [3:0] change_due = pending_change + {1'b0, new_change};
    wire pay_change = change_due != 4'd0;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            d1_sampled <= 1'b0;
            d2_sampled <= 1'b0;
            credit <= 3'd0;
            pending_change <= 4'd0;
            {out1, out2, out3} <= 3'b000;
        end else begin
            d1_sampled <= d1;
            d2_sampled <= d2;

            credit <= vend ? 3'd0 : total;
            pending_change <= pay_change ? change_due - 4'd1 : 4'd0;
            out1 <= vend && !sel;
            out2 <= vend && sel;
            // Each asserted cycle dispenses one half-yuan coin.
            out3 <= pay_change;
        end
    end
endmodule
