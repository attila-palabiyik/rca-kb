module TopModule(
    input clk,
    input rst_n,
    input set,
    input [3:0] set_num,
    output reg [3:0] number,
    output reg zero
);
    wire [3:0] next_number = set ? set_num : number + 4'd1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            number <= 4'd0;
            zero <= 1'b1;
        end else begin
            number <= next_number;
            zero <= (next_number == 4'd0);
        end
    end
endmodule
