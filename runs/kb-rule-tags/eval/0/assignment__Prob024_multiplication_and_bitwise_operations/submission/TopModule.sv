module TopModule(
    input  [7:0]    A,
    output [15:0]   B
    );

    wire [10:0] five_a;

    // 0xFB = 256 - 5.
    assign five_a = {1'b0, A, 2'b00} + {3'b0, A};
    assign B = {A, 8'b0} - {5'b0, five_a};

endmodule
