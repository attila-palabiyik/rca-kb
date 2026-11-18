module TopModule(
    input  [7:0]    A,
    output [15:0]   B
    );

//*************code***********//

    // 251 = 256 - 5. The shifts are wiring, and 5*A fits in 11 bits.
    wire [10:0] five_a;
    assign five_a = {1'b0, A, 2'b00} + {3'b000, A};
    assign B = {A, 8'b0} - {5'b0, five_a};
//*************code***********//

endmodule
