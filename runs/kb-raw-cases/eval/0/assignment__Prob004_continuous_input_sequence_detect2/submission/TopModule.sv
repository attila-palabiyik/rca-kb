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
        if (data_valid) begin
            case (pstate)
                idle:             nstate = data ? idle : s1_d0;
                s1_d0, s4_d0110:   nstate = data ? s2_d01 : s1_d0;
                s2_d01:           nstate = data ? s3_d011 : s1_d0;
                s3_d011:          nstate = data ? idle : s4_d0110;
                default:          nstate = idle;
            endcase
        end else begin
            // End the match pulse while retaining its trailing zero.
            nstate = (pstate == s4_d0110) ? s1_d0 : pstate;
        end
    end

    always @* begin
        match = rst_n && (pstate == s4_d0110);
    end

endmodule
