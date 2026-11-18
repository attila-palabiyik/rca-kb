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
    reg d1_held, d2_held;

    wire d1_pulse = d1_sampled && !d1_held;
    wire d2_pulse = d2_sampled && !d2_held;

    // Consume each pulse at the falling edge and rearm after a low sample.
    always @(negedge clk or negedge rst) begin
        if (!rst) begin
            d1_held <= 1'b0;
            d2_held <= 1'b0;
        end else begin
            if (d1_pulse)
                d1_held <= 1'b1;
            else if (!d1_sampled)
                d1_held <= 1'b0;

            if (d2_pulse)
                d2_held <= 1'b1;
            else if (!d2_sampled)
                d2_held <= 1'b0;
        end
    end

    // Amounts are expressed in half-yuan units. Use the same input sample
    // that starts each coin pulse so the purchase can complete on that edge.
    reg [2:0] credit;
    reg [2:0] change_pending;
    wire [2:0] deposit = {2'b00, d1 && !d1_held}
                       + {1'b0, d2 && !d2_held, 1'b0};
    wire [2:0] total = credit + deposit;
    wire [2:0] price = sel ? 3'd5 : 3'd3;
    wire vend = total >= price;
    wire [2:0] new_change = vend ? total - price : 3'd0;
    wire [3:0] change_due = {1'b0, change_pending} + {1'b0, new_change};

    reg change_issue, change_ack;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            d1_sampled <= 1'b0;
            d2_sampled <= 1'b0;
            credit <= 3'd0;
            change_pending <= 3'd0;
            change_issue <= 1'b0;
            out1 <= 1'b0;
            out2 <= 1'b0;
        end else begin
            d1_sampled <= d1;
            d2_sampled <= d2;
            credit <= vend ? 3'd0 : total;
            out1 <= vend && !sel;
            out2 <= vend && sel;

            if (change_due != 4'd0) begin
                change_pending <= change_due - 4'd1;
                change_issue <= !change_issue;
            end
        end
    end

    // Acknowledge the issued coin on the falling edge to end its pulse.
    always @(negedge clk or negedge rst) begin
        if (!rst)
            change_ack <= 1'b0;
        else
            change_ack <= change_issue;
    end

    always @(*) begin
        out3 = rst && (change_issue != change_ack);
    end
endmodule
