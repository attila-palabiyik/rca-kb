module TopModule(
    input  [7:0]    A,
    output [15:0]   B
    );

//*************code***********//

    wire [10:0] five_times_a;

    // 0xFB = 256 - 5, and 5 = 4 + 1.
    assign five_times_a = {1'b0, A, 2'b00} + {3'b000, A};
    assign B = {A, 8'b00000000} - {5'b00000, five_times_a};
//*************code***********//

endmodule
