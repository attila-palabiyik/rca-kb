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

    // Credit, prices, and change are measured in half-yuan coins.
    reg [2:0] credit;
    reg [2:0] change_due;

    reg [1:0] previous_inputs;
    reg [1:0] sampled_edges;
    wire [1:0] coin_inputs = {d2, d1};
    wire [1:0] coin_edges = coin_inputs & ~previous_inputs;
    wire [2:0] inserted = {1'b0, coin_edges};
    wire [2:0] price = sel ? 3'd5 : 3'd3;

    // Each accepted input has a pulse confined to the high clock phase.
    wire d1_pulse = clk & sampled_edges[0];
    wire d2_pulse = clk & sampled_edges[1];

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            previous_inputs <= 2'b00;
            sampled_edges   <= 2'b00;
            credit          <= 3'd0;
            change_due      <= 3'd0;
        end else begin
            previous_inputs <= coin_inputs;
            sampled_edges   <= coin_edges;
            if (out1 || out2) begin
                credit     <= inserted;
                change_due <= change_due + (credit - price) - {2'b00, out3};
            end else begin
                credit <= credit + inserted;
                if (out3)
                    change_due <= change_due - 3'd1;
            end
        end
    end

    always @(*) begin
        {out1, out2, out3} = 3'b000;
        if (rst) begin
            out1 = !sel && (credit >= price);
            out2 = sel && (credit >= price);
            // Each asserted cycle dispenses one half-yuan coin.
            out3 = (change_due != 3'd0) || (credit > price);
        end
    end
endmodule
