module TopModule(
    input clk,
    input rst_n,
    output wire data
    );
     
    reg [5:0] q;
     
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            q <= 6'b001011;
        else
            q <= {q[4:0], q[5]};
    end

    assign data = q[5];
endmodule
