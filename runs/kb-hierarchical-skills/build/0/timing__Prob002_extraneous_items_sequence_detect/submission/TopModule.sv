module TopModule(
    input  wire clk,
    input  wire rst_n,
    input  wire a,
    output reg  match
);

    reg [8:0] history;
    reg [3:0] sample_count;
    wire [8:0] next_history = {history[7:0], a};

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            history <= 9'b0;
            sample_count <= 4'd0;
            match <= 1'b0;
        end else begin
            history <= next_history;
            // Eight earlier samples plus a make a complete window.
            if (sample_count < 4'd8)
                sample_count <= sample_count + 4'd1;

            match <= (sample_count == 4'd8)
                     && (next_history[8:6] == 3'b011)
                     && (next_history[2:0] == 3'b110);
        end
    end

endmodule
