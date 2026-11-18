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
    // All amounts are measured in half-yuan units.
    localparam [2:0] PRICE1 = 3'd3, PRICE2 = 3'd5;
    reg [2:0] balance;
    reg [3:0] change_pending;

    reg [1:0] coin_sample, coin_previous;
    wire [1:0] coin_pulse = coin_sample & ~coin_previous;
    wire [2:0] deposit = {1'b0, coin_pulse};
    wire vend1 = !sel && balance >= PRICE1;
    wire vend2 = sel && balance >= PRICE2;
    wire [2:0] change_from_sale = vend1 ? balance - PRICE1 :
                                  vend2 ? balance - PRICE2 : 3'd0;
    wire [3:0] change_due = change_pending + {1'b0, change_from_sale};

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            coin_sample <= 2'b00;
            {out1, out2, out3} <= 3'b000;
            change_pending <= 4'd0;
        end else begin
            coin_sample <= {d2, d1};
            out1 <= vend1;
            out2 <= vend2;
            out3 <= change_due != 4'd0;
            // Each asserted output cycle pays one half-yuan coin.
            change_pending <= change_due != 4'd0 ? change_due - 4'd1 : 4'd0;
        end
    end

    // Updating the history here ends each coin pulse on the falling edge.
    // This edge credits new deposits, including coins sampled during a sale.
    always @(negedge clk or negedge rst) begin
        if (!rst) begin
            coin_previous <= 2'b00;
            balance <= 3'd0;
        end else begin
            coin_previous <= coin_sample;
            balance <= ((out1 || out2) ? 3'd0 : balance) + deposit;
        end
    end
endmodule
