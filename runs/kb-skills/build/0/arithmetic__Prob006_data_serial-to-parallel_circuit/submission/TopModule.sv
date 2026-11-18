module TopModule(
    input               clk         ,  
    input               rst_n       ,
    input               valid_a     ,
    input               data_a      ,
  
    output  wire        ready_a     ,
    output  reg         valid_b     ,
    output  reg [5:0]   data_b
);
    reg [5:0] data_r;
    reg [2:0] cnt;
    wire word_complete = valid_a && (cnt == 3'd5);

    assign ready_a = 1'b1;

    always@(posedge clk or negedge rst_n) begin
        if (!rst_n)
            cnt <= 3'd0;
        else if (valid_a)
            cnt <= word_complete ? 3'd0 : cnt + 3'd1;
    end
     
    always@(posedge clk or negedge rst_n) begin
        if(~rst_n)
            data_r <= 6'b0;
        else if (valid_a)
            data_r <= {data_a, data_r[5:1]};
    end
     
    always@(posedge clk or negedge rst_n) begin
        if(~rst_n)
            data_b <= 6'b0;
        else if (word_complete)
            data_b <= {data_a, data_r[5:1]};
    end
     
    always@(posedge clk or negedge rst_n) begin
        if(~rst_n)
            valid_b <= 1'b0;
        else
            valid_b <= word_complete;
    end
endmodule
