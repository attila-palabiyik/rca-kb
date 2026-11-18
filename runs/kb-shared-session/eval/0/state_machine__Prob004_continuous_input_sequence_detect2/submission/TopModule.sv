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
        if (!rst_n)
            pstate <= idle;
        else
            pstate <= nstate;
    end

    always @(*) begin
        nstate = pstate;
        case (pstate)
            idle: if (data_valid && !data) nstate = s1_d0;
            s1_d0: if (data_valid && data) nstate = s2_d01;
            s2_d01: if (data_valid) nstate = data ? s3_d011 : s1_d0;
            s3_d011: if (data_valid) nstate = data ? idle : s4_d0110;
            // End the pulse while keeping the trailing zero as a prefix.
            s4_d0110: nstate = (data_valid && data) ? s2_d01 : s1_d0;
            default: nstate = idle;
        endcase
    end

    always @(*) begin
        match = rst_n && (pstate == s4_d0110);
    end
endmodule
