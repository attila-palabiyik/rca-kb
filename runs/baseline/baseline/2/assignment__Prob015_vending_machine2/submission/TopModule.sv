module TopModule(
    input  wire clk,
    input  wire rst,
    input  wire d1,
    input  wire d2,
    input  wire sel,
    output reg  out1,
    output reg  out2,
    output reg  out3
);
    reg sampled_d1, sampled_d2, sampled_sel;
    reg previous_d1, previous_d2;

    // Sample on the rising edge and end each new coin pulse on the falling edge.
    wire d1_pulse = sampled_d1 & ~previous_d1;
    wire d2_pulse = sampled_d2 & ~previous_d2;

    // All amounts are in units of 0.5 yuan.
    reg [2:0] credit;
    reg [2:0] pending_change;
    wire [2:0] inserted = {1'b0, d2_pulse, d1_pulse};
    wire [2:0] total = credit + inserted;
    wire [2:0] price = sampled_sel ? 3'd5 : 3'd3;
    wire vend = total >= price;
    wire [2:0] new_change = vend ? total - price : 3'd0;
    wire [2:0] change_due = pending_change + new_change;
    wire dispense_change = change_due != 3'd0;

    reg hold_out1, hold_out2;

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

    always @(negedge clk or negedge rst) begin
        if (!rst) begin
            previous_d1 <= 1'b0;
            previous_d2 <= 1'b0;
            credit <= 3'd0;
            pending_change <= 3'd0;
            hold_out1 <= 1'b0;
            hold_out2 <= 1'b0;
        end else begin
            previous_d1 <= sampled_d1;
            previous_d2 <= sampled_d2;
            credit <= vend ? 3'd0 : total;
            pending_change <= dispense_change ? change_due - 3'd1 : 3'd0;
            hold_out1 <= vend & ~sampled_sel;
            hold_out2 <= vend & sampled_sel;
        end
    end

    always @(*) begin
        out1 = rst && (clk ? (vend & ~sampled_sel) : hold_out1);
        out2 = rst && (clk ? (vend & sampled_sel) : hold_out2);
        // The low phase separates consecutive 0.5-yuan change pulses.
        out3 = rst && clk && dispense_change;
    end
endmodule
