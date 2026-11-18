module TopModule(
    input clk,
    input rst_n,
    input a,
    output reg match
);

    reg [8:0] a_tem;
    reg [3:0] sample_count;
    wire [8:0] next_a_tem = {a_tem[7:0], a};

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_tem <= 9'b0;
            sample_count <= 4'd0;
            match <= 1'b0;
        end else begin
            a_tem <= next_a_tem;
            // Eight prior samples plus the current bit make a full window.
            if (sample_count < 4'd8)
                sample_count <= sample_count + 4'd1;

            match <= (sample_count == 4'd8) &&
                     (next_a_tem[8:6] == 3'b011) &&
                     (next_a_tem[2:0] == 3'b110);
        end
    end
endmodule
