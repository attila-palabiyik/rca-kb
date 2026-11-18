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
    reg sampled_d1, sampled_d2, sampled_sel;
    reg previous_d1, previous_d2;
    wire coin_half = sampled_d1 & ~previous_d1;
    wire coin_one = sampled_d2 & ~previous_d2;

    // All amounts are in half-yuan units.
    reg [2:0] credit;
    reg [2:0] change_due;
    wire [2:0] total = credit + {1'b0, coin_one, coin_half};
    wire [2:0] price = sampled_sel ? 3'd5 : 3'd3;
    wire vend = total >= price;
    wire [2:0] new_change = vend ? total - price : 3'd0;
    wire [2:0] change_to_pay = change_due + new_change;
    wire pay_change = change_to_pay != 3'd0;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            sampled_d1 <= 1'b0;
            sampled_d2 <= 1'b0;
            sampled_sel <= 1'b0;
        end else begin
            sampled_d1 <= d1;
            sampled_d2 <= d2;
            sampled_sel <= sel;
        end
    end

    // The coin pulses last until the falling edge, when the transaction
    // is recorded and any dispensed change coin is deducted.
    always @(negedge clk or negedge rst) begin
        if (!rst) begin
            previous_d1 <= 1'b0;
            previous_d2 <= 1'b0;
            credit <= 3'd0;
            change_due <= 3'd0;
        end else begin
            previous_d1 <= sampled_d1;
            previous_d2 <= sampled_d2;
            credit <= vend ? 3'd0 : total;
            change_due <= change_to_pay - {2'b00, pay_change};
        end
    end

    always @(*) begin
        out1 = rst && clk && vend && !sampled_sel;
        out2 = rst && clk && vend && sampled_sel;
        out3 = rst && clk && pay_change;
    end
endmodule
