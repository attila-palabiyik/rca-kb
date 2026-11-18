module TopModule(
    input clk,
    input rst_n,
    input data,
    input data_valid,
    output reg match
);

reg [3:0] pstate, nstate;

parameter idle     = 4'd0,
          s1_d0    = 4'd1,
          s2_d01   = 4'd2,
          s3_d011  = 4'd3,
          s4_d0110 = 4'd4;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        pstate <= idle;
    else
        pstate <= nstate;
end

always @* begin
    nstate = pstate;

    case (pstate)
        idle:
            if (data_valid && !data)
                nstate = s1_d0;
        s1_d0:
            if (data_valid && data)
                nstate = s2_d01;
        s2_d01:
            if (data_valid)
                nstate = data ? s3_d011 : s1_d0;
        s3_d011:
            if (data_valid)
                nstate = data ? idle : s4_d0110;
        s4_d0110: begin
            // Reuse the final zero as the first bit of a possible next match.
            nstate = s1_d0;
            if (data_valid && data)
                nstate = s2_d01;
        end
        default:
            nstate = idle;
    endcase
end

always @* begin
    match = rst_n && (pstate == s4_d0110);
end

endmodule
