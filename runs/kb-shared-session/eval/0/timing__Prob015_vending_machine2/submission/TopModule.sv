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
    reg [2:0] change_due;

    // Credit, prices, and change are measured in half-yuan units.
    wire coin_half = d1 && !prev_d1;
    wire coin_one = d2 && !prev_d2;
    wire [2:0] inserted = {1'b0, coin_one, coin_half};
    wire [2:0] price = sel ? 3'd5 : 3'd3;
    wire [2:0] change = credit - price;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            prev_d1 <= 1'b0;
            prev_d2 <= 1'b0;
            credit <= 3'd0;
            change_due <= 3'd0;
            {out1, out2, out3} <= 3'b000;
        end else begin
            prev_d1 <= d1;
            prev_d2 <= d2;
            {out1, out2, out3} <= 3'b000;
            credit <= credit + inserted;

            if (change_due != 0) begin
                out3 <= 1'b1;
                change_due <= change_due - 3'd1;
            end else if (credit >= price) begin
                out1 <= !sel;
                out2 <= sel;
                // Coins sampled on the sale edge start the next purchase.
                credit <= inserted;
                if (change != 0) begin
                    out3 <= 1'b1;
                    change_due <= change - 3'd1;
                end
            end
        end
    end
endmodule
