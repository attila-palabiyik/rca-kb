module TopModule(
    input  [7:0]    A,
    output [15:0]   B
    );

//*************code***********//

    wire [10:0] five_a;

    // 251 = 256 - (4 + 1).
    assign five_a = {1'b0, A, 2'b00} + {3'b000, A};
    assign B = {A, 8'b0} - {5'b00000, five_a};
//*************code***********//

endmodule
