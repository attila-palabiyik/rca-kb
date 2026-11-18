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
    reg d1_edge, d2_edge;
    reg selected;
    reg rising_phase, falling_phase;

    reg d1_pulse, d2_pulse;

    // All amounts are in half-yuan units.
    reg [2:0] credit, next_credit;
    reg [2:0] change_due, next_change_due;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            prev_d1 <= 1'b0;
            prev_d2 <= 1'b0;
            d1_edge <= 1'b0;
            d2_edge <= 1'b0;
            selected <= 1'b0;
            rising_phase <= 1'b0;
        end else begin
            prev_d1 <= d1;
            prev_d2 <= d2;
            d1_edge <= d1 & ~prev_d1;
            d2_edge <= d2 & ~prev_d2;
            selected <= sel;
            rising_phase <= ~rising_phase;
        end
    end

    always @(negedge clk or negedge rst) begin
        if (!rst) begin
            falling_phase <= 1'b0;
            credit <= 3'd0;
            change_due <= 3'd0;
        end else begin
            falling_phase <= rising_phase;
            credit <= next_credit;
            change_due <= next_change_due;
        end
    end

    always @* begin : transaction
        reg pulse_window, vend, dispense_change;
        reg [2:0] total, price, refund;

        // The falling edge commits the transaction and closes the pulse window.
        pulse_window = rst && (rising_phase ^ falling_phase);
        d1_pulse = pulse_window && d1_edge;
        d2_pulse = pulse_window && d2_edge;
        total = credit + {1'b0, d2_pulse, d1_pulse};
        price = selected ? 3'd5 : 3'd3;
        vend = pulse_window && (total >= price);
        refund = vend ? change_due + (total - price) : change_due;
        dispense_change = pulse_window && (refund != 3'd0);

        next_credit = vend ? 3'd0 : total;
        next_change_due = dispense_change ? refund - 3'd1 : refund;
        out1 = vend && !selected;
        out2 = vend && selected;
        out3 = dispense_change;
    end
endmodule
