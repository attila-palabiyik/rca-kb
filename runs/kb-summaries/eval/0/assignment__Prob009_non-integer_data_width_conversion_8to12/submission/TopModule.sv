module TopModule (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_in,
    input  wire [7:0]  data_in,
    output reg         valid_out,
    output reg  [11:0] data_out
);

reg       first_pending;
reg [7:0] first_byte;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        first_pending <= 1'b0;
        first_byte    <= 8'b0;
        valid_out     <= 1'b0;
        data_out      <= 12'b0;
    end else begin
        valid_out <= valid_in && first_pending;
        if (valid_in) begin
            first_pending <= !first_pending;
            if (first_pending)
                data_out <= {first_byte, data_in[7:4]};
            else
                first_byte <= data_in;
        end
    end
end

endmodule
