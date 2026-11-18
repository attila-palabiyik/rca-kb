module TopModule #(
    parameter N = 7
) (
    input  wire rst,
    input  wire clk_in,
    output wire clk_out7
);
    localparam integer COUNT_WIDTH = (N > 1) ? $clog2(N) : 1;
    localparam [COUNT_WIDTH-1:0] LAST_COUNT = COUNT_WIDTH'(N - 1);
    localparam [COUNT_WIDTH-1:0] HIGH_START = COUNT_WIDTH'((N - 1) / 2);

    reg [COUNT_WIDTH-1:0] cnt;
    reg clkp;
    reg clkn;

    always @(posedge clk_in or negedge rst) begin
        if (!rst) begin
            cnt  <= '0;
            clkp <= 1'b0;
        end else if (cnt == LAST_COUNT) begin
            cnt  <= '0;
            clkp <= 1'b0;
        end else begin
            cnt <= cnt + 1'b1;
            if (cnt == HIGH_START)
                clkp <= 1'b1;
        end
    end

    always @(negedge clk_in or negedge rst) begin
        if (!rst)
            clkn <= 1'b0;
        else
            clkn <= clkp;
    end

    // For odd divisors, the falling-edge copy extends the high pulse by half a cycle.
    assign clk_out7 = (N == 1) ? (clk_in & rst) :
                     clkp | (clkn & (N % 2 != 0));
endmodule
