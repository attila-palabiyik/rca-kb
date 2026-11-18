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
    reg d1_sample, d2_sample;
    reg d1_previous, d2_previous;

    // The falling edge ends each pulse and saves the sample for the next cycle.
    wire d1_pulse = d1_sample & ~d1_previous;
    wire d2_pulse = d2_sample & ~d2_previous;

    // An input is eligible until its rising-edge pulse records acceptance.
    wire d1_inserted = d1 & ~(d1_previous | d1_pulse);
    wire d2_inserted = d2 & ~(d2_previous | d2_pulse);

    always @(negedge clk or negedge rst) begin
        if (!rst) begin
            d1_previous <= 1'b0;
            d2_previous <= 1'b0;
        end else begin
            d1_previous <= d1_sample;
            d2_previous <= d2_sample;
        end
    end

    // All amounts are in units of 0.5 yuan.
    reg [2:0] credit;
    reg [3:0] change_due;

    wire [2:0] total = credit + {1'b0, d2_inserted, d1_inserted};
    wire [2:0] price = sel ? 3'd5 : 3'd3;
    wire vend = total >= price;
    wire [2:0] overpayment = vend ? total - price : 3'd0;
    wire [3:0] change_available = change_due + {1'b0, overpayment};

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            d1_sample <= 1'b0;
            d2_sample <= 1'b0;
            credit <= 3'd0;
            change_due <= 4'd0;
            {out1, out2, out3} <= 3'b000;
        end else begin
            d1_sample <= d1;
            d2_sample <= d2;
            credit <= vend ? 3'd0 : total;

            out1 <= vend & ~sel;
            out2 <= vend & sel;
            out3 <= change_available != 4'd0;
            change_due <= change_available == 4'd0
                        ? 4'd0 : change_available - 4'd1;
        end
    end
endmodule
