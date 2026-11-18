module TopModule(
    input  clk,
    input  rst_n,
    input  a,
    output reg match
);

    reg [8:0] history;
    wire [8:0] next_history = {history[7:0], a};

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // A leading reset bit of 1 prevents matches before nine samples.
            history <= 9'b111111111;
            match <= 1'b0;
        end else begin
            history <= next_history;
            match <= (next_history[8:6] == 3'b011) &&
                     (next_history[2:0] == 3'b110);
        end
    end
endmodule
