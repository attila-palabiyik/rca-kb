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
    reg [1:0] previous_coins;
    reg [1:0] new_coins;
    reg [2:0] base_credit;
    reg [2:0] saved_credit;
    reg [1:0] pending_change;

    // All amounts are in units of 0.5 yuan. The two coin bits have weights 2 and 1.
    wire [2:0] price = sel ? 3'd5 : 3'd3;
    wire [1:0] coin_pulses = new_coins & {2{clk}};
    wire [2:0] credit = clk
        ? base_credit + {1'b0, coin_pulses}
        : saved_credit;

    wire vend = credit >= price;
    wire [2:0] change_due = vend ? credit - price : 3'd0;

    // Use the settled credit from the preceding low phase to complete a sale.
    wire sale_complete = saved_credit >= price;
    wire [2:0] sale_change = sale_complete ? saved_credit - price : 3'd0;
    wire [2:0] total_change = {1'b0, pending_change} + sale_change;
    wire [2:0] remaining_change = total_change - 3'd1;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            previous_coins <= 2'b00;
            new_coins <= 2'b00;
            base_credit <= 3'd0;
            pending_change <= 2'd0;
        end else begin
            previous_coins <= {d2, d1};
            new_coins <= {d2, d1} & ~previous_coins;
            base_credit <= sale_complete ? 3'd0 : saved_credit;
            // A high out3 pays one coin per clock, starting in the sale cycle.
            pending_change <= total_change == 0 ? 2'd0 : remaining_change[1:0];
        end
    end

    // Retain the accumulated credit when the coin pulses end.
    always @(negedge clk or negedge rst) begin
        if (!rst)
            saved_credit <= 3'd0;
        else
            saved_credit <= base_credit + {1'b0, new_coins};
    end

    always @(*) begin
        out1 = rst && vend && !sel;
        out2 = rst && vend && sel;
        out3 = rst && (pending_change != 0 || change_due != 0);
    end
endmodule
