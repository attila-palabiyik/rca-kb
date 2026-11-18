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
    // Balances and prices are measured in half-yuan units.
    localparam [2:0] PRICE1 = 3'd3, PRICE2 = 3'd5;

    reg [1:0] previous_coins;
    reg [1:0] sampled_edges;
    reg [2:0] balance;
    reg [2:0] pending_change;

    wire [1:0] coin_edges = {d2, d1} & ~previous_coins;
    wire [1:0] coin_pulses = sampled_edges & {2{clk}};
    wire [2:0] inserted = {1'b0, coin_edges};
    wire [2:0] price = sel ? PRICE2 : PRICE1;
    wire dispense = balance >= price;
    wire [2:0] change_due = dispense ? balance - price : 3'd0;
    wire [3:0] available_change = {1'b0, pending_change} + {1'b0, change_due};

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            previous_coins <= 2'b00;
            sampled_edges <= 2'b00;
            balance <= 3'd0;
            pending_change <= 3'd0;
        end else begin
            previous_coins <= {d2, d1};
            sampled_edges <= coin_edges;
            balance <= (dispense ? 3'd0 : balance) + inserted;
            // Each asserted output cycle dispenses one half-yuan coin.
            pending_change <= out3 ? (available_change[2:0] - 3'd1) : 3'd0;
        end
    end

    always @(*) begin
        out1 = rst && dispense && !sel;
        out2 = rst && dispense && sel;
        out3 = rst && (available_change != 4'd0);
    end
endmodule
