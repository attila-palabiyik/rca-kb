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
    reg [1:0] previous_inputs;
    reg [1:0] coin_edges;
    reg [1:0] acknowledged_edges;
    reg selection;
    wire [1:0] coin_pulses = coin_edges ^ acknowledged_edges;

    // Each bit toggles on a sampled input rise and is acknowledged at the fall.
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            previous_inputs <= 2'b00;
            coin_edges <= 2'b00;
            selection <= 1'b0;
        end else begin
            previous_inputs <= {d2, d1};
            coin_edges <= coin_edges ^ ({d2, d1} & ~previous_inputs);
            selection <= sel;
        end
    end

    // All amounts are measured in half-yuan coins.
    reg [2:0] credit, next_credit;
    reg [2:0] change_due, next_change_due;
    reg [2:0] cycle_outputs, held_outputs;
    wire [2:0] price = selection ? 3'd5 : 3'd3;
    wire [2:0] inserted = {1'b0, coin_pulses[1], 1'b0}
                        + {2'b00, coin_pulses[0]};

    always @(*) begin
        next_credit = credit + inserted;
        next_change_due = change_due;
        cycle_outputs = 3'b000;

        if (next_credit >= price) begin
            cycle_outputs[2:1] = selection ? 2'b01 : 2'b10;
            next_change_due = change_due + (next_credit - price);
            next_credit = 3'd0;
        end

        if (next_change_due != 3'd0) begin
            cycle_outputs[0] = 1'b1;
            next_change_due = next_change_due - 3'd1;
        end
    end

    // Commit the transaction as the coin pulses end. Hold its outputs
    // through the low phase so each dispense signal lasts a full cycle.
    always @(negedge clk or negedge rst) begin
        if (!rst) begin
            acknowledged_edges <= 2'b00;
            credit <= 3'd0;
            change_due <= 3'd0;
            held_outputs <= 3'b000;
        end else begin
            acknowledged_edges <= coin_edges;
            credit <= next_credit;
            change_due <= next_change_due;
            held_outputs <= cycle_outputs;
        end
    end

    always @(*) begin
        if (!rst)
            {out1, out2, out3} = 3'b000;
        else
            {out1, out2, out3} = clk ? cycle_outputs : held_outputs;
    end
endmodule
