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
    reg [1:0] previous_inputs;
    reg [1:0] new_coins;
    reg selected_beverage;
    reg rising_phase, falling_phase;

    // The phase bits differ during the high half of each clock cycle.
    wire pulse_active = rising_phase ^ falling_phase;
    wire [1:0] coin_pulses = new_coins & {2{pulse_active}};

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            previous_inputs <= 2'b00;
            new_coins <= 2'b00;
            selected_beverage <= 1'b0;
            rising_phase <= 1'b0;
        end else begin
            previous_inputs <= {d2, d1};
            new_coins <= {d2, d1} & ~previous_inputs;
            selected_beverage <= sel;
            rising_phase <= ~rising_phase;
        end
    end

    // Credit, prices, and change are measured in half-yuan coins.
    reg [2:0] credit;
    reg [3:0] change_due;
    reg [1:0] dispensed;

    wire [2:0] total = credit + {1'b0, coin_pulses[1], 1'b0}
                              + {2'b00, coin_pulses[0]};
    wire [2:0] price = selected_beverage ? 3'd5 : 3'd3;
    wire vend = total >= price;
    wire [1:0] beverage = {vend && !selected_beverage,
                           vend && selected_beverage};
    wire [2:0] overpayment = vend ? total - price : 3'd0;
    wire [3:0] change_available = change_due + {1'b0, overpayment};

    always @(negedge clk or negedge rst) begin
        if (!rst) begin
            falling_phase <= 1'b0;
            credit <= 3'd0;
            change_due <= 4'd0;
            dispensed <= 2'b00;
        end else begin
            falling_phase <= rising_phase;
            credit <= vend ? 3'd0 : total;
            change_due <= change_available == 4'd0
                          ? 4'd0 : change_available - 4'd1;
            dispensed <= beverage;
        end
    end

    always @(*) begin
        // Hold the beverage output for the full cycle. Each change coin
        // gets a high-phase pulse so consecutive coins have a low interval.
        {out1, out2} = pulse_active ? beverage : dispensed;
        out3 = pulse_active && (change_available != 4'd0);
        if (!rst)
            {out1, out2, out3} = 3'b000;
    end
endmodule
