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
    // All amounts are in half-yuan units.
    localparam [2:0] PRICE_1 = 3'd3;
    localparam [2:0] PRICE_2 = 3'd5;

    reg previous_d1, previous_d2;
    reg [2:0] credit;
    reg [2:0] change_pending;

    wire coin1 = d1 && !previous_d1;
    wire coin2 = d2 && !previous_d2;
    wire [2:0] total = credit + {1'b0, coin2, coin1};
    wire [2:0] price = sel ? PRICE_2 : PRICE_1;
    wire vend = (total >= price);
    wire [2:0] new_change = vend ? total - price : 3'd0;
    wire [3:0] change_due = {1'b0, change_pending} + {1'b0, new_change};

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            previous_d1 <= 1'b0;
            previous_d2 <= 1'b0;
            credit <= 3'd0;
            change_pending <= 3'd0;
            out1 <= 1'b0;
            out2 <= 1'b0;
            out3 <= 1'b0;
        end else begin
            previous_d1 <= d1;
            previous_d2 <= d2;
            credit <= vend ? 3'd0 : total;
            out1 <= vend && !sel;
            out2 <= vend && sel;

            // Dispense one half-yuan coin per cycle while change is due.
            out3 <= (change_due != 4'd0);
            change_pending <= (change_due == 4'd0) ? 3'd0 : change_due[2:0] - 3'd1;
        end
    end
endmodule
