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
    reg [1:0] coin_sample, coin_previous;
    wire [1:0] coins = {d2, d1};
    wire [1:0] coin_rise = coins & ~coin_previous;
    wire [1:0] coin_pulse = coin_sample & ~coin_previous;

    // Amounts are measured in half-yuan units.
    reg [2:0] credit;
    reg [2:0] change_due;
    wire [2:0] inserted = {1'b0, coin_rise};
    wire [2:0] price = sel ? 3'd5 : 3'd3;
    wire vend = (change_due == 3'd0) && (credit >= price);

    // Capture the input on the rising edge and end each pulse on the falling edge.
    always @(negedge clk or negedge rst) begin
        if (!rst)
            coin_previous <= 2'b00;
        else
            coin_previous <= coin_sample;
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            coin_sample <= 2'b00;
            credit      <= 3'd0;
            change_due  <= 3'd0;
        end else begin
            coin_sample <= coins;

            if (vend) begin
                // A coin sampled at the end of a sale starts the next balance.
                credit <= inserted;
                if (credit > price)
                    change_due <= credit - price - 3'd1;
            end else begin
                credit <= credit + inserted;
                if (change_due != 3'd0)
                    change_due <= change_due - 3'd1;
            end
        end
    end

    always @(*) begin
        out1 = rst && vend && !sel;
        out2 = rst && vend && sel;
        // Issue the first change coin with the drink and one per cycle thereafter.
        out3 = rst && ((change_due != 3'd0) || (vend && (credit > price)));
    end
endmodule
