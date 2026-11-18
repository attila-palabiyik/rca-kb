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
    wire [1:0] coin_inputs = {d2, d1};
    reg [1:0] sampled_inputs, previous_inputs;
    wire [1:0] coin_pulse = sampled_inputs & ~previous_inputs;
    reg [2:0] credit;
    reg [2:0] pending_change;

    // The rising edge captures the inputs and starts each new coin pulse.
    // The falling edge ends those pulses and saves the sample for the next cycle.
    always @(negedge clk or negedge rst) begin
        if (!rst)
            previous_inputs <= 2'b00;
        else
            previous_inputs <= sampled_inputs;
    end

    // Count the same edges as coin_pulse on the rising edge that starts them.
    // The bit weights already express the amount in half-yuan coins.
    wire [1:0] inserted = coin_inputs & ~previous_inputs;
    wire [2:0] total = credit + {1'b0, inserted};
    wire [2:0] price = sel ? 3'd5 : 3'd3;
    wire vend = total >= price;
    wire [2:0] overpayment = vend ? total - price : 3'd0;
    wire [2:0] change_due = pending_change + overpayment;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            sampled_inputs <= 2'b00;
            credit <= 3'd0;
            pending_change <= 3'd0;
            {out1, out2, out3} <= 3'b000;
        end else begin
            sampled_inputs <= coin_inputs;
            credit <= vend ? 3'd0 : total;
            out1 <= vend && !sel;
            out2 <= vend && sel;

            // Each asserted cycle pays one coin, starting on the vend cycle.
            out3 <= change_due != 3'd0;
            pending_change <= change_due != 3'd0 ? change_due - 3'd1 : 3'd0;
        end
    end
endmodule
