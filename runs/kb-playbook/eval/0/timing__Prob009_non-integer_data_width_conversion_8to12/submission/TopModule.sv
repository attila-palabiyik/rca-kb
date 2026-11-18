module TopModule(
    input             clk,
    input             rst_n,
    input             valid_in,
    input      [7:0]  data_in,
    output reg        valid_out,
    output reg [11:0] data_out
);
    reg [7:0] first_byte;
    reg       have_first;

    wire pair_complete = valid_in && have_first;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            first_byte <= 8'd0;
            have_first <= 1'b0;
            valid_out  <= 1'b0;
            data_out   <= 12'd0;
        end else begin
            valid_out <= pair_complete;
            if (valid_in)
                have_first <= !have_first;

            if (pair_complete)
                data_out <= {first_byte, data_in[7:4]};
            else if (valid_in)
                first_byte <= data_in;
        end
    end
endmodule
