module TopModule(
    input clk,
    input rst_n,
    input data,
    input data_valid,
    output reg match
);
    parameter idle = 4'd0,
              s1_d0 = 4'd1,
              s2_d01 = 4'd2,
              s3_d011 = 4'd3,
              s4_d0110 = 4'd4;

    reg [3:0] pstate, nstate;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pstate <= idle;
            match <= 1'b0;
        end else begin
            pstate <= nstate;
            match <= (nstate == s4_d0110);
        end
    end

    always @(*) begin
        case (pstate)
            idle: nstate = (data_valid && !data) ? s1_d0 : idle;
            // A completed match leaves a trailing 0 for the next match.
            s1_d0, s4_d0110: nstate = (data_valid && data) ? s2_d01 : s1_d0;
            s2_d01: nstate = data_valid ? (data ? s3_d011 : s1_d0) : s2_d01;
            s3_d011: nstate = data_valid ? (data ? idle : s4_d0110) : s3_d011;
            default: nstate = idle;
        endcase
    end
endmodule
