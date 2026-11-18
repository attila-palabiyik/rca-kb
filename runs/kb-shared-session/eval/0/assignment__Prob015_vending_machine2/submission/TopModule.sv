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
    reg prev_d1, prev_d2;
    reg [2:0] credit;
    reg [3:0] pending_change;

    // All amounts are in half-yuan units.
    wire [2:0] deposit = (d1 && !prev_d1 ? 3'd1 : 3'd0)
                       + (d2 && !prev_d2 ? 3'd2 : 3'd0);
    wire [2:0] total = credit + deposit;
    wire [2:0] price = sel ? 3'd5 : 3'd3;
    wire vend = (total >= price);
    wire [2:0] refund = vend ? total - price : 3'd0;
    wire [3:0] change_due = pending_change + {1'b0, refund};
    wire pay_change = (change_due != 4'd0);

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            prev_d1 <= 1'b0;
            prev_d2 <= 1'b0;
            credit <= 3'd0;
            pending_change <= 4'd0;
            {out1, out2, out3} <= 3'b000;
        end else begin
            prev_d1 <= d1;
            prev_d2 <= d2;
            credit <= vend ? 3'd0 : total;
            pending_change <= pay_change ? change_due - 4'd1 : 4'd0;
            out1 <= vend && !sel;
            out2 <= vend && sel;
            out3 <= pay_change;
        end
    end
endmodule
