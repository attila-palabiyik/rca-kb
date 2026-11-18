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
    reg sampled_d1, sampled_d2;
    reg previous_d1, previous_d2;

    // The rising edge samples the coin inputs and uses the same edge
    // condition for accounting. Updating history on the falling edge
    // ends each pulse without resampling the inputs.
    wire new_d1 = d1 && !previous_d1;
    wire new_d2 = d2 && !previous_d2;
    wire d1_pulse = sampled_d1 && !previous_d1;
    wire d2_pulse = sampled_d2 && !previous_d2;

    always @(negedge clk or negedge rst) begin
        if (!rst) begin
            previous_d1 <= 1'b0;
            previous_d2 <= 1'b0;
        end else begin
            previous_d1 <= sampled_d1;
            previous_d2 <= sampled_d2;
        end
    end

    // Credit, price, and change are all measured in half-yuan coins.
    reg [2:0] credit;
    reg [2:0] change_due;

    wire [2:0] inserted = {1'b0, new_d2, new_d1};
    wire [2:0] total = credit + inserted;
    wire [2:0] price = sel ? 3'd5 : 3'd3;
    wire vend = total >= price;
    wire [2:0] change_added = vend ? total - price : 3'd0;
    wire [3:0] change_available = {1'b0, change_due} + {1'b0, change_added};
    wire [3:0] change_remaining = change_available - 4'd1;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            sampled_d1 <= 1'b0;
            sampled_d2 <= 1'b0;
            credit <= 3'd0;
            change_due <= 3'd0;
            {out1, out2, out3} <= 3'b000;
        end else begin
            sampled_d1 <= d1;
            sampled_d2 <= d2;
            credit <= vend ? 3'd0 : total;
            out1 <= vend && !sel;
            out2 <= vend && sel;

            // Each asserted clock cycle pays one coin, starting with the vend.
            out3 <= change_available != 4'd0;
            change_due <= (change_available != 4'd0) ? change_remaining[2:0] : 3'd0;
        end
    end
endmodule
