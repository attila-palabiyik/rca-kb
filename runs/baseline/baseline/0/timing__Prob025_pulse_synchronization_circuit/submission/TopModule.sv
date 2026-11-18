module TopModule(
    input  clk_fast,
    input  clk_slow,
    input  rst_n,
    input  data_in,
    output data_out
);
    reg Q_fast;
    reg Q_buff0;
    reg Q_buff1;
    reg Q_slow;

    always @(posedge clk_fast or negedge rst_n) begin
        if (!rst_n)
            Q_fast <= 1'b0;
        else if (data_in)
            Q_fast <= ~Q_fast;
    end

    // Synchronize the toggle, then retain its previous slow-clock value.
    always @(posedge clk_slow or negedge rst_n) begin
        if (!rst_n) begin
            Q_buff0 <= 1'b0;
            Q_buff1 <= 1'b0;
            Q_slow  <= 1'b0;
        end else begin
            Q_buff0 <= Q_fast;
            Q_buff1 <= Q_buff0;
            Q_slow  <= Q_buff1;
        end
    end

    assign data_out = Q_buff1 ^ Q_slow;
endmodule
