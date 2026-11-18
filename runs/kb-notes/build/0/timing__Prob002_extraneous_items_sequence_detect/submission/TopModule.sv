module TopModule (
    input clk,
    input rst_n,
    input a,
    output reg match
);

    reg [8:0] history;
    reg [3:0] samples_seen;
    wire [8:0] next_history = {history[7:0], a};

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            history <= 9'b0;
            samples_seen <= 4'd0;
            match <= 1'b0;
        end else begin
            history <= next_history;

            // Eight prior samples plus a make a complete window.
            if (samples_seen < 4'd8)
                samples_seen <= samples_seen + 4'd1;

            match <= (samples_seen == 4'd8) &&
                     (next_history[8:6] == 3'b011) &&
                     (next_history[2:0] == 3'b110);
        end
    end
endmodule
