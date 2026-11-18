module TopModule(
    input clk,
    input rst_n,
    input a,
    output reg match
);

    reg [8:0] a_tem;
    wire [8:0] next_window = {a_tem[7:0], a};

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Until nine bits arrive, the oldest bit must prevent a match.
            a_tem <= 9'b111111111;
            match <= 1'b0;
        end else begin
            a_tem <= next_window;
            match <= (next_window[8:6] == 3'b011) &&
                     (next_window[2:0] == 3'b110);
        end
    end
endmodule
