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
    localparam [2:0] PRICE1 = 3'd3, PRICE2 = 3'd5;

    reg [1:0] sampled_coins, previous_coins;
    reg [2:0] credit;
    reg [2:0] change_due;
    reg return_toggle, return_ack;

    wire [1:0] coin_inputs = {d2, d1};
    wire [1:0] coin_edges = coin_inputs & ~previous_coins;
    // Expose each accepted deposit for the high phase of its sampling cycle.
    wire [1:0] coin_pulse = sampled_coins & ~previous_coins;

    // Credit is counted in half-yuan units. At most four carry into a cycle.
    wire [2:0] total = credit + {1'b0, coin_edges[1], 1'b0}
                              + {2'b00, coin_edges[0]};
    wire [2:0] price = sel ? PRICE2 : PRICE1;
    wire vend = total >= price;
    wire [2:0] change = vend ? total - price : 3'd0;
    wire [2:0] coins_to_return = change_due + change;
    wire return_coin = coins_to_return != 3'd0;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            sampled_coins <= 2'b00;
            credit <= 3'd0;
            change_due <= 3'd0;
            return_toggle <= 1'b0;
            out1 <= 1'b0;
            out2 <= 1'b0;
        end else begin
            sampled_coins <= coin_inputs;
            credit <= vend ? 3'd0 : total;
            out1 <= vend & ~sel;
            out2 <= vend & sel;
            return_toggle <= return_toggle ^ return_coin;
            change_due <= return_coin ? coins_to_return - 3'd1 : 3'd0;
        end
    end

    // End the deposit and change pulses on the falling edge.
    always @(negedge clk or negedge rst) begin
        if (!rst) begin
            previous_coins <= 2'b00;
            return_ack <= 1'b0;
        end else begin
            previous_coins <= sampled_coins;
            return_ack <= return_toggle;
        end
    end

    always @(*) begin
        out3 = rst & (return_toggle ^ return_ack);
    end
endmodule
