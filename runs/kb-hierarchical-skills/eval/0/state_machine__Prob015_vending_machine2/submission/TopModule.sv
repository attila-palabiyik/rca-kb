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
    // Credit and change are measured in 0.5-yuan units.
    localparam [2:0] PRICE_1 = 3'd3;
    localparam [2:0] PRICE_2 = 3'd5;

    reg [2:0] credit;
    reg [1:0] change_pending;
    reg [1:0] coin_sample;
    reg [1:0] coin_previous;
    reg change_request, change_ack;

    // Bits 0 and 1 represent the 0.5-yuan and 1-yuan inputs, respectively.
    wire [1:0] coins = {d2, d1};
    wire [1:0] new_coins = coins & ~coin_previous;
    wire [1:0] coin_pulse = coin_sample & ~coin_previous;
    wire [2:0] total = credit + {1'b0, new_coins};
    wire [2:0] price = sel ? PRICE_2 : PRICE_1;
    wire vend = total >= price;
    wire [2:0] excess = total - price;

    wire [2:0] change_due = {1'b0, change_pending} +
                            (vend ? excess : 3'd0);
    wire dispense_change = change_due != 3'd0;
    wire [2:0] change_remaining = change_due - {2'b00, dispense_change};

    // Acknowledge each coin on the falling edge to separate successive pulses.
    always @*
        out3 = rst && (change_request ^ change_ack);

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            change_pending <= 2'd0;
            coin_sample    <= 2'd0;
            change_request <= 1'b0;
            out1           <= 1'b0;
            out2           <= 1'b0;
        end else begin
            coin_sample    <= coins;
            change_pending <= change_remaining[1:0];
            change_request <= change_request ^ dispense_change;
            out1           <= vend && !sel;
            out2           <= vend && sel;
        end
    end

    // Commit credit and clear the input pulses on the falling edge.
    always @(negedge clk or negedge rst) begin
        if (!rst) begin
            credit        <= 3'd0;
            coin_previous <= 2'd0;
            change_ack    <= 1'b0;
        end else begin
            credit        <= (out1 || out2) ? 3'd0 : credit + {1'b0, coin_pulse};
            coin_previous <= coin_sample;
            change_ack    <= change_request;
        end
    end
endmodule
