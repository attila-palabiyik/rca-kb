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

    assign ready_a = 1'b1;
 
    always@(posedge clk or negedge rst_n) begin
        if(~rst_n)
            cnt <= 0;
        else
            cnt <= ~ready_a||~valid_a? cnt:
                   cnt      ==      5? 0  :
                   cnt+1;
    end
     
    always@(posedge clk or negedge rst_n) begin
        if(~rst_n)
            data_r <= 6'b0;
        else
            data_r <= ready_a&&valid_a? {data_a, data_r[5:1]}: data_r;
    end
     
    wire word_complete = ready_a && valid_a && (cnt == 3'd5);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_b <= 6'b0;
            valid_b <= 1'b0;
        end else begin
            valid_b <= word_complete;
            if (word_complete)
                data_b <= {data_a, data_r[5:1]};
        end
    end
endmodule
