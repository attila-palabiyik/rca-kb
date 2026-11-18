module TopModule (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_in,
    input  wire [7:0]  data_in,
    output reg         valid_out,
    output reg  [11:0] data_out
);

    reg [7:0] first_byte;
    reg       have_first;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            first_byte <= 8'd0;
            have_first <= 1'b0;
            valid_out  <= 1'b0;
            data_out   <= 12'd0;
        end else begin
            valid_out <= valid_in && have_first;
            if (valid_in) begin
                have_first <= !have_first;
                if (have_first)
                    data_out <= {first_byte, data_in[7:4]};
                else
                    first_byte <= data_in;
            end
        end
    end

endmodule
