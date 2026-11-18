module TopModule(
    input clk,
    input rst_n,
    input write_en,
    input [7:0] write_addr,
    input [3:0] write_data,
    input read_en,
    input [7:0] read_addr,
    output reg [3:0] read_data
);
    localparam DEPTH = 8;
    reg [3:0] myRAM [0:DEPTH-1];
    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < DEPTH; i = i + 1)
                myRAM[i] <= 4'b0;
        end else if (write_en && write_addr < DEPTH) begin
            myRAM[write_addr[2:0]] <= write_data;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            read_data <= 4'b0;
        else if (read_en)
            read_data <= (read_addr < DEPTH) ? myRAM[read_addr[2:0]] : 4'b0;
    end
endmodule
