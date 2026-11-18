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
    localparam [7:0] DEPTH = 8'd8;
    reg [3:0] myRAM [0:DEPTH-1];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (integer i = 0; i < DEPTH; i = i + 1)
                myRAM[i] <= 4'b0000;
            read_data <= 4'b0000;
        end else begin
            if (write_en && write_addr < DEPTH)
                myRAM[write_addr[2:0]] <= write_data;
            if (read_en && read_addr < DEPTH)
                read_data <= myRAM[read_addr[2:0]];
        end
    end
endmodule
