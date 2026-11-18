module TopModule(
    input  [7:0]    A,
    output [15:0]   B
    );

    wire [10:0] five_a;

    // 251 = 256 - (4 + 1). The shifts are implemented by wiring.
    assign five_a = {1'b0, A, 2'b00} + {3'b000, A};
    assign B = {A, 8'b0} - {5'b0, five_a};

endmodule
