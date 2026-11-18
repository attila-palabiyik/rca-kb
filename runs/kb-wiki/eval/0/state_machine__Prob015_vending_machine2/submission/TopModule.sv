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
    reg [1:0] sampled_coins;
    reg [1:0] previous_coins;

    // Use the incoming edge at the same rising edge that samples the coin.
    wire [1:0] coin_edges = {d2, d1} & ~previous_coins;

    // The sampled edge stays high until the falling edge copies the sample.
    wire [1:0] coin_pulses = sampled_coins & ~previous_coins;

    always @(posedge clk or negedge rst) begin
        if (!rst)
            sampled_coins <= 2'b00;
        else
            sampled_coins <= {d2, d1};
    end

    always @(negedge clk or negedge rst) begin
        if (!rst)
            previous_coins <= 2'b00;
        else
            previous_coins <= sampled_coins;
    end

    // Balances are measured in half-yuan coins.
    reg [31:0] credit;
    reg [31:0] change_due;
    wire [31:0] total = credit + {30'b0, coin_edges};
    wire [31:0] price = sel ? 32'd5 : 32'd3;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            credit     <= 32'd0;
            change_due <= 32'd0;
            out1       <= 1'b0;
            out2       <= 1'b0;
            out3       <= 1'b0;
        end else begin
            credit <= total;
            out1   <= 1'b0;
            out2   <= 1'b0;
            out3   <= 1'b0;

            if (change_due != 0) begin
                if (!out3) begin
                    out3       <= 1'b1;
                    change_due <= change_due - 32'd1;
                end
            end else if (!(out1 || out2 || out3) && total >= price) begin
                credit <= 32'd0;
                out1   <= !sel;
                out2   <= sel;
                if (total > price) begin
                    out3       <= 1'b1;
                    change_due <= total - price - 32'd1;
                end
            end
        end
    end
endmodule
