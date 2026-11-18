module TopModule(
    input clk,
    input rst_n,
    output reg [3:0] gray_out
);
    reg advance;
    wire [3:0] gray_wire = gray_out;
    wire [3:0] binary = {
        gray_wire[3], ^gray_wire[3:2], ^gray_wire[3:1], ^gray_wire
    };
    wire [3:0] next_binary = binary + 4'd1;
    wire [3:0] next_gray = next_binary ^ (next_binary >> 1);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            advance <= 1'b0;
            gray_out <= 4'b0;
        end else begin
            advance <= ~advance;
            if (advance)
                gray_out <= next_gray;
        end
    end
endmodule
