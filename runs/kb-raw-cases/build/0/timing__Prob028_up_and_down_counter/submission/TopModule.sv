module TopModule(
    input clk,
    input rst_n,
    input mode,
    output reg [3:0] number,
    output reg zero
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            number <= 4'd0;
            zero <= 1'b0;
        end else begin
            // Report whether the count was zero before this clock edge.
            zero <= (number == 4'd0);

            if (mode) begin
                if (number == 4'd9)
                    number <= 4'd0;
                else
                    number <= number + 4'd1;
            end else if (!mode) begin
                if (number == 4'd0)
                    number <= 4'd9;
                else
                    number <= number - 4'd1;
            end
        end
    end
endmodule
