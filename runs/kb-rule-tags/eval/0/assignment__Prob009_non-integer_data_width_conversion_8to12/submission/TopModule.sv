module TopModule (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_in,
    input  wire [7:0]  data_in,
    output reg         valid_out,
    output reg  [11:0] data_out
);
    reg [7:0] first_byte;
    reg       have_first_byte;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            first_byte      <= 8'b0;
            have_first_byte <= 1'b0;
            valid_out       <= 1'b0;
            data_out        <= 12'b0;
        end else begin
            valid_out <= valid_in && have_first_byte;

            if (valid_in) begin
                have_first_byte <= !have_first_byte;
                if (have_first_byte)
                    data_out <= {first_byte, data_in[3:0]};
                else
                    first_byte <= data_in;
            end
        end
    end
endmodule
