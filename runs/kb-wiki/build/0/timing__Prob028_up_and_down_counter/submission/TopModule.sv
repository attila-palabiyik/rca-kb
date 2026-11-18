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
            zero <= (number == 4'd0);

            if (mode)
                number <= (number == 4'd9) ? 4'd0 : number + 4'd1;
            else if (!mode)
                number <= (number == 4'd0) ? 4'd9 : number - 4'd1;
        end
    end

endmodule
