module TopModule #(
    parameter N = 7
) (
    input  wire rst,
    input  wire clk_in,
    output wire clk_out7
);
    localparam COUNT_WIDTH = (N > 1) ? $clog2(N) : 1;
    localparam [COUNT_WIDTH-1:0] LAST_COUNT = COUNT_WIDTH'(N - 1);
    localparam [COUNT_WIDTH-1:0] HIGH_START = COUNT_WIDTH'((N - 1) / 2);

    reg [COUNT_WIDTH-1:0] cnt;
    reg clkp;

    always @(posedge clk_in or negedge rst) begin
        if (!rst) begin
            cnt  <= '0;
            clkp <= 1'b0;
        end else begin
            if (cnt == LAST_COUNT)
                cnt <= '0;
            else
                cnt <= cnt + 1'b1;

            clkp <= (cnt >= HIGH_START) && (cnt < LAST_COUNT);
        end
    end

    generate
        if (N % 2 == 1) begin : odd_divisor
            reg clkn;

            // For odd N, extend the high pulse to the next falling edge.
            always @(negedge clk_in or negedge rst) begin
                if (!rst)
                    clkn <= 1'b0;
                else
                    clkn <= clkp;
            end

            assign clk_out7 = clkp | clkn;
        end else begin : even_divisor
            assign clk_out7 = clkp;
        end
    endgenerate
endmodule
