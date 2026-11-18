module TopModule(
    input  [7:0]    A,
    output [15:0]   B
    );

//*************code***********//

    wire [10:0] five_a;

    // 0xFB = 256 - 5. The concatenations implement shifts by wiring.
    assign five_a = {1'b0, A, 2'b00} + {3'b000, A};
    assign B = {A, 8'b0} - {5'b00000, five_a};
//*************code***********//

endmodule
