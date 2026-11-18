module TopModule #(
    parameter N = 7
) (
    input  wire rst,
    input  wire clk_in,
    output wire clk_out7
);

    localparam integer COUNT_WIDTH = (N > 1) ? $clog2(N) : 1;
    localparam [COUNT_WIDTH-1:0] LAST_COUNT = COUNT_WIDTH'(N - 1);
    localparam [COUNT_WIDTH-1:0] HALF_COUNT = COUNT_WIDTH'(N / 2);

    generate
        if (N == 1) begin : divide_by_one
            assign clk_out7 = rst & clk_in;
        end else begin : divider
            reg [COUNT_WIDTH-1:0] cnt;
            reg clkp;

            always @(posedge clk_in or negedge rst) begin
                if (!rst) begin
                    cnt  <= '0;
                    clkp <= 1'b0;
                end else begin
                    cnt  <= (cnt == LAST_COUNT) ? '0 : cnt + 1'b1;
                    clkp <= cnt < HALF_COUNT;
                end
            end

            if (N % 2 == 0) begin : even_divisor
                assign clk_out7 = clkp;
            end else begin : odd_divisor
                reg clkn;

                always @(negedge clk_in or negedge rst) begin
                    if (!rst)
                        clkn <= 1'b0;
                    else
                        clkn <= clkp;
                end

                // Stretch the high pulse by half an input clock cycle.
                assign clk_out7 = clkp | clkn;
            end
        end
    endgenerate
endmodule
