module TopModule(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_in,
    input  wire [7:0]  data_in,
    output reg         valid_out,
    output reg  [11:0] data_out
);

reg [7:0] data_lock;
reg       have_first_byte;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_lock       <= 8'd0;
        have_first_byte <= 1'b0;
        valid_out       <= 1'b0;
        data_out        <= 12'd0;
    end else begin
        valid_out <= valid_in && have_first_byte;

        if (valid_in) begin
            have_first_byte <= !have_first_byte;
            if (have_first_byte)
                data_out <= {data_lock, data_in[3:0]};
            else
                data_lock <= data_in;
        end
    end
end

endmodule
