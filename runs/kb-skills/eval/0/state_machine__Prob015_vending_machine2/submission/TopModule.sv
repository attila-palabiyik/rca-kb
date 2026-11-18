module TopModule (
    input wire clk,
    input wire rst,
    input wire d1,
    input wire d2,
    input wire sel,
    output reg out1,
    output reg out2,
    output reg out3
);
    reg [1:0] sampled_coins, held_coins;
    wire [1:0] coin_inputs = {d2, d1};
    wire [1:0] new_coins = coin_inputs & ~held_coins;
    wire [1:0] coin_pulses = sampled_coins & ~held_coins;

    // Capture inputs on the rising edge and end new coin pulses on the falling edge.
    always @(posedge clk or negedge rst) begin
        if (!rst)
            sampled_coins <= 2'b00;
        else
            sampled_coins <= coin_inputs;
    end

    always @(negedge clk or negedge rst) begin
        if (!rst)
            held_coins <= 2'b00;
        else
            held_coins <= (held_coins & sampled_coins) | coin_pulses;
    end

    // The bit positions of new_coins encode the deposit in half-yuan units.
    reg [2:0] credit, change_due;
    wire [2:0] total_credit = credit + {1'b0, new_coins};
    wire [2:0] price = sel ? 3'd5 : 3'd3;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            credit <= 3'd0;
            change_due <= 3'd0;
            {out1, out2, out3} <= 3'b000;
        end else begin
            credit <= total_credit;
            {out1, out2, out3} <= 3'b000;

            if (change_due != 3'd0) begin
                out3 <= 1'b1;
                change_due <= change_due - 3'd1;
            end else if (total_credit >= price) begin
                out1 <= !sel;
                out2 <= sel;
                credit <= 3'd0;

                // Send the first change coin with the beverage.
                if (total_credit > price) begin
                    out3 <= 1'b1;
                    change_due <= total_credit - price - 3'd1;
                end
            end
        end
    end
endmodule
