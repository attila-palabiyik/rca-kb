module TopModule(
    input  [7:0]    A,
    output [15:0]   B
    );

    // 251 = 256 - 5, and 5 = 4 + 1.
    wire [10:0] times_five;
    assign times_five = {1'b0, A, 2'b00} + {3'b000, A};
    assign B = {A, 8'b0} - {5'b00000, times_five};

endmodule
